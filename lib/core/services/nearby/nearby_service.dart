import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../settings_service.dart';
import 'nearby_crypto.dart';
import 'nearby_models.dart';

/// Coordinates LAN advertise / discover / send / receive for vault items.
class NearbyService {
  NearbyService._();
  static final NearbyService instance = NearbyService._();

  static const serviceType = '_clipval-nearby._tcp';
  static const protocolVersion = NearbyCrypto.protocolVersion;
  static const _offerTimeout = Duration(seconds: 55);
  static const _discoverWindow = Duration(seconds: 4);

  final _uuid = const Uuid();
  final _devices = <String, NearbyDevice>{};
  final _deviceController = StreamController<List<NearbyDevice>>.broadcast();

  HttpServer? _server;
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;

  String? _deviceId;
  String _deviceName = 'ClipVal';
  bool _running = false;

  /// Session PIN (6 digits). Regenerated each time Nearby starts.
  String? _sessionPin;
  final _pinController = StreamController<String?>.broadcast();

  /// UI listens here — offers are already dequeued one-at-a-time.
  final _offerController = StreamController<NearbyIncomingOffer>.broadcast();
  final Queue<NearbyIncomingOffer> _offerQueue = Queue<NearbyIncomingOffer>();
  bool _presentingOffer = false;

  Stream<NearbyIncomingOffer> get incomingOffers => _offerController.stream;
  Stream<String?> get sessionPin$ => _pinController.stream;
  String? get sessionPin => _sessionPin;

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

  Future<void> startIfEnabled() async {
    await init();
    if (!SettingsService.instance.nearbyEnabled) {
      await stop();
      return;
    }
    if (_running) return;
    try {
      _sessionPin = NearbyCrypto.generatePin();
      _pinController.add(_sessionPin);
      await _startServer();
      await _startBroadcast();
      _running = true;
      _log('started on port ${_server?.port} as $_deviceName (pin session)');
    } catch (e, st) {
      _log('start failed: $e\n$st');
      await stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    _running = false;
    // Reject anything still waiting.
    while (_offerQueue.isNotEmpty) {
      _offerQueue.removeFirst().reject();
    }
    _presentingOffer = false;
    _sessionPin = null;
    _pinController.add(null);

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

  /// Rotate PIN (Settings refresh). Keeps server up.
  void rotatePin() {
    if (!_running) return;
    _sessionPin = NearbyCrypto.generatePin();
    _pinController.add(_sessionPin);
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
      await stop();
      await startIfEnabled();
    }
  }

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
    required String pin,
    String? categoryName,
    bool isSensitive = false,
  }) async {
    if (!SettingsService.instance.nearbyEnabled) {
      return const NearbySendReport(NearbySendResult.disabled);
    }
    if (!NearbyCrypto.isValidPin(pin)) {
      return const NearbySendReport(NearbySendResult.badPin);
    }
    await init();

    final sealed = NearbyCrypto.encryptValue(
      value: value,
      pin: pin,
      receiverDeviceId: device.id,
    );

    final wire = NearbyOfferWire(
      fromName: _deviceName,
      fromId: _deviceId!,
      title: title,
      pin: pin,
      ciphertext: sealed.ciphertext,
      nonce: sealed.nonce,
      mac: sealed.mac,
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
            body: jsonEncode(wire.toJson()),
          )
          .timeout(_offerTimeout + const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return const NearbySendReport(NearbySendResult.accepted);
      }
      if (res.statusCode == 401) {
        return const NearbySendReport(NearbySendResult.badPin);
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
        .addMiddleware(_cors())
        .addHandler(router.call);

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
        'pinRequired': true,
      }),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    );
  }

  Future<Response> _handleOffer(Request request) async {
    if (!SettingsService.instance.nearbyEnabled || _sessionPin == null) {
      return Response(
        403,
        body: jsonEncode({'accepted': false, 'reason': 'disabled'}),
      );
    }
    Map<String, dynamic> jsonBody;
    try {
      final raw = await request.readAsString();
      jsonBody = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return Response(400, body: jsonEncode({'error': 'invalid_json'}));
    }

    final wire = NearbyOfferWire.tryParse(jsonBody);
    if (wire == null) {
      return Response(400, body: jsonEncode({'error': 'invalid_offer'}));
    }

    // Constant-time-ish PIN check (length already constrained).
    if (!_pinMatches(wire.pin)) {
      return Response(401, body: jsonEncode({'error': 'bad_pin'}));
    }

    final plain = NearbyCrypto.decryptValue(
      ciphertext: wire.ciphertext,
      nonce: wire.nonce,
      pin: wire.pin,
      receiverDeviceId: _deviceId!,
      mac: wire.mac,
    );
    if (plain == null || plain.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'decrypt_failed'}));
    }

    final payload = NearbyOfferPayload(
      fromName: wire.fromName,
      fromId: wire.fromId,
      title: wire.title,
      value: plain,
      categoryName: wire.categoryName,
      isSensitive: wire.isSensitive,
    );

    final completer = Completer<bool>();
    final offer = NearbyIncomingOffer(payload: payload, completer: completer);
    _enqueueOffer(offer);

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
      if (!completer.isCompleted) completer.complete(false);
      return Response(
        408,
        body: jsonEncode({'accepted': false, 'reason': 'timeout'}),
      );
    }
  }

  bool _pinMatches(String pin) {
    final expected = _sessionPin;
    if (expected == null || pin.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ pin.codeUnitAt(i);
    }
    return diff == 0;
  }

  void _enqueueOffer(NearbyIncomingOffer offer) {
    _offerQueue.add(offer);
    _pumpOfferQueue();
  }

  void _pumpOfferQueue() {
    if (_presentingOffer || _offerQueue.isEmpty) return;
    if (!_offerController.hasListener) {
      // No UI — reject all queued.
      while (_offerQueue.isNotEmpty) {
        _offerQueue.removeFirst().reject();
      }
      return;
    }
    _presentingOffer = true;
    final next = _offerQueue.removeFirst();
    _offerController.add(next);
    next.completer.future.whenComplete(() {
      _presentingOffer = false;
      _pumpOfferQueue();
    });
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
    developer.log(m, name: 'clipval.nearby');
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
