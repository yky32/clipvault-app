import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../settings_service.dart';
import 'nearby_models.dart';

/// Coordinates LAN advertise / discover / send / receive for vault items.
class NearbyService {
  NearbyService._();
  static final NearbyService instance = NearbyService._();

  static const serviceType = '_clipval-nearby._tcp';
  static const protocolVersion = 1;
  static const _offerTimeout = Duration(seconds: 55);
  static const _discoverWindow = Duration(seconds: 4);

  final _uuid = const Uuid();
  final _devices = <String, NearbyDevice>{}; // key = id or host:port
  final _deviceController = StreamController<List<NearbyDevice>>.broadcast();

  HttpServer? _server;
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;

  String? _deviceId;
  String _deviceName = 'ClipVal';
  bool _running = false;

  /// Incoming offers waiting for UI Accept/Reject.
  final _offerController = StreamController<NearbyIncomingOffer>.broadcast();
  Stream<NearbyIncomingOffer> get incomingOffers => _offerController.stream;

  Stream<List<NearbyDevice>> get devices$ => _deviceController.stream;
  List<NearbyDevice> get devices =>
      _devices.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  bool get isRunning => _running;
  String get deviceName => _deviceName;
  String get deviceId => _deviceId ?? '';

  Future<void> init() async {
    _deviceId = SettingsService.instance.nearbyDeviceId;
    if (_deviceId == null || _deviceId!.isEmpty) {
      _deviceId = _uuid.v4();
      await SettingsService.instance.setNearbyDeviceId(_deviceId!);
    }
    _deviceName = SettingsService.instance.nearbyDisplayName;
    if (_deviceName.trim().isEmpty) {
      _deviceName = 'ClipVal';
    }
  }

  /// Start HTTP + Bonjour when user enabled Nearby in Settings.
  Future<void> startIfEnabled() async {
    await init();
    if (!SettingsService.instance.nearbyEnabled) {
      await stop();
      return;
    }
    if (_running) return;
    try {
      await _startServer();
      await _startBroadcast();
      _running = true;
      _log('started on port ${_server?.port} as $_deviceName');
    } catch (e, st) {
      _log('start failed: $e\n$st');
      await stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    _running = false;
    await _discoverySub?.cancel();
    _discoverySub = null;
    try {
      await _discovery?.stop();
    } catch (_) {}
    _discovery = null;
    try {
      await _broadcast?.stop();
    } catch (_) {}
    _broadcast = null;
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    _devices.clear();
    _emitDevices();
    _log('stopped');
  }

  Future<void> setEnabled(bool enabled) async {
    await SettingsService.instance.setNearbyEnabled(enabled);
    if (enabled) {
      await startIfEnabled();
    } else {
      await stop();
    }
  }

  Future<void> updateDisplayName(String name) async {
    final n = name.trim().isEmpty ? 'ClipVal' : name.trim();
    _deviceName = n;
    await SettingsService.instance.setNearbyDisplayName(n);
    if (_running) {
      // Re-advertise with new name.
      await stop();
      await startIfEnabled();
    }
  }

  /// Active scan for a few seconds; also returns cached list.
  Future<List<NearbyDevice>> discover({
    Duration window = _discoverWindow,
  }) async {
    await init();
    await _ensureDiscovery();
    await Future<void>.delayed(window);
    return devices;
  }

  Future<NearbySendReport> sendItem({
    required NearbyDevice device,
    required String title,
    required String value,
    String? categoryName,
    bool isSensitive = false,
  }) async {
    if (!SettingsService.instance.nearbyEnabled) {
      return const NearbySendReport(NearbySendResult.disabled);
    }
    await init();
    final payload = NearbyOfferPayload(
      fromName: _deviceName,
      fromId: _deviceId!,
      title: title,
      value: value,
      categoryName: categoryName,
      isSensitive: isSensitive,
    );
    final uri = device.baseUri.replace(path: '/v1/offer');
    try {
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload.toJson()),
          )
          .timeout(_offerTimeout + const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return const NearbySendReport(NearbySendResult.accepted);
      }
      if (res.statusCode == 403) {
        return const NearbySendReport(NearbySendResult.rejected);
      }
      if (res.statusCode == 408) {
        return const NearbySendReport(NearbySendResult.timeout);
      }
      return NearbySendReport(
        NearbySendResult.error,
        message: 'HTTP ${res.statusCode}',
      );
    } on TimeoutException {
      return const NearbySendReport(NearbySendResult.timeout);
    } on SocketException catch (e) {
      return NearbySendReport(
        NearbySendResult.unreachable,
        message: e.message,
      );
    } catch (e) {
      return NearbySendReport(NearbySendResult.error, message: '$e');
    }
  }

  // ── Server ────────────────────────────────────────────────────────────

  Future<void> _startServer() async {
    final router = Router();
    router.get('/v1/ping', _handlePing);
    router.post('/v1/offer', _handleOffer);

    final handler = const Pipeline()
        .addMiddleware(logRequests(logger: (m, isError) {
          if (isError) _log(m);
        }))
        .addMiddleware(_cors())
        .addHandler(router.call);

    // Bind all interfaces so LAN peers can connect.
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 0);
    _server!.autoCompress = true;
  }

  Middleware _cors() {
    return (inner) {
      return (request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final res = await inner(request);
        return res.change(headers: _corsHeaders);
      };
    };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Accept',
  };

  Future<Response> _handlePing(Request request) async {
    return Response.ok(
      jsonEncode({
        'ok': true,
        'protocolVersion': protocolVersion,
        'deviceId': _deviceId,
        'name': _deviceName,
      }),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );
  }

  Future<Response> _handleOffer(Request request) async {
    if (!SettingsService.instance.nearbyEnabled) {
      return Response(403, body: jsonEncode({'accepted': false, 'reason': 'disabled'}));
    }
    Map<String, dynamic> json;
    try {
      final raw = await request.readAsString();
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'invalid_json'}));
    }
    final payload = NearbyOfferPayload.fromJson(json);
    if (payload == null || payload.value.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'empty_item'}));
    }

    final completer = Completer<bool>();
    final offer = NearbyIncomingOffer(payload: payload, completer: completer);
    if (!_offerController.hasListener) {
      // No UI attached — reject so sender is not stuck forever.
      _log('offer with no UI listener — reject');
      return Response(403, body: jsonEncode({'accepted': false, 'reason': 'no_ui'}));
    }
    _offerController.add(offer);

    try {
      final accepted = await completer.future.timeout(_offerTimeout);
      if (accepted) {
        return Response.ok(
          jsonEncode({'accepted': true}),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
        );
      }
      return Response(403, body: jsonEncode({'accepted': false}));
    } on TimeoutException {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return Response(408, body: jsonEncode({'accepted': false, 'reason': 'timeout'}));
    }
  }

  // ── Discovery ─────────────────────────────────────────────────────────

  Future<void> _startBroadcast() async {
    final port = _server?.port;
    if (port == null) return;
    final service = BonsoirService(
      name: _deviceName,
      type: serviceType,
      port: port,
      attributes: {
        'id': _deviceId ?? '',
        'v': '$protocolVersion',
      },
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.ready;
    await _broadcast!.start();
  }

  Future<void> _ensureDiscovery() async {
    if (_discovery != null) return;
    _discovery = BonsoirDiscovery(type: serviceType);
    await _discovery!.ready;
    _discoverySub = _discovery!.eventStream?.listen(_onDiscoveryEvent);
    await _discovery!.start();
  }

  Future<void> _onDiscoveryEvent(BonsoirDiscoveryEvent event) async {
    final service = event.service;
    if (service == null) return;

    if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
      try {
        await service.resolve(_discovery!.serviceResolver);
      } catch (e) {
        _log('resolve failed: $e');
      }
      return;
    }

    if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
      final resolvedHost = _readHost(service);
      final port = service.port;
      if (resolvedHost == null || resolvedHost.isEmpty || port <= 0) return;

      final id = service.attributes['id'] ?? '$resolvedHost:$port';
      if (id == _deviceId) return;

      final device = NearbyDevice(
        id: id,
        name: service.name,
        host: resolvedHost,
        port: port,
      );
      _devices[id] = device;
      _emitDevices();
      return;
    }

    if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
      final id = service.attributes['id'] ?? service.name;
      _devices.removeWhere((k, v) => k == id || v.name == service.name);
      _emitDevices();
    }
  }

  String? _readHost(BonsoirService s) {
    if (s is ResolvedBonsoirService) {
      final h = s.host;
      if (h != null && h.isNotEmpty) return h;
    }
    try {
      final j = s.toJson();
      for (final key in ['service.host', 'host']) {
        final h = j[key];
        if (h != null && '$h'.isNotEmpty) return '$h';
      }
    } catch (_) {}
    return null;
  }

  void _emitDevices() {
    if (!_deviceController.isClosed) {
      _deviceController.add(devices);
    }
  }

  static void _log(String m) {
    // ignore: avoid_print
    print('[ClipVal Nearby] $m');
  }
}

/// Offer delivered to UI; complete [completer] with accept/reject.
class NearbyIncomingOffer {
  NearbyIncomingOffer({
    required this.payload,
    required this.completer,
  });

  final NearbyOfferPayload payload;
  final Completer<bool> completer;

  void accept() {
    if (!completer.isCompleted) completer.complete(true);
  }

  void reject() {
    if (!completer.isCompleted) completer.complete(false);
  }
}
