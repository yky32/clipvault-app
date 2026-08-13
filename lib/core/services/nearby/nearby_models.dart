/// Nearby (LAN) vault item transfer — LocalSend-inspired, item-only MVP.
///
/// Protocol v1 (HTTP on local Wi‑Fi, no ClipVal cloud):
/// - Advertise: Bonjour `_clipval-nearby._tcp`
/// - GET  /v1/ping  → device card
/// - POST /v1/offer → hold until receiver Accept/Reject (timeout ~55s)
///
/// Trust model: same LAN + explicit human Accept (like AirDrop).
/// Values travel only on the local network; no ClipVal server.
library;

class NearbyDevice {
  const NearbyDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
  });

  final String id;
  final String name;
  final String host;
  final int port;

  Uri get baseUri => Uri(scheme: 'http', host: host, port: port);

  @override
  String toString() => 'NearbyDevice($name @ $host:$port)';
}

class NearbyOfferPayload {
  const NearbyOfferPayload({
    required this.fromName,
    required this.fromId,
    required this.title,
    required this.value,
    this.categoryName,
    this.isSensitive = false,
  });

  final String fromName;
  final String fromId;
  final String title;
  final String value;
  final String? categoryName;
  final bool isSensitive;

  Map<String, dynamic> toJson() => {
        'protocolVersion': 1,
        'fromName': fromName,
        'fromId': fromId,
        'title': title,
        'value': value,
        if (categoryName != null && categoryName!.isNotEmpty)
          'categoryName': categoryName,
        'isSensitive': isSensitive,
      };

  static NearbyOfferPayload? fromJson(Map<String, dynamic> json) {
    final title = json['title']?.toString() ?? '';
    final value = json['value']?.toString() ?? '';
    if (title.trim().isEmpty && value.trim().isEmpty) return null;
    return NearbyOfferPayload(
      fromName: json['fromName']?.toString() ?? 'ClipVal',
      fromId: json['fromId']?.toString() ?? '',
      title: title.trim().isEmpty
          ? (value.length > 32 ? '${value.substring(0, 32)}…' : value)
          : title,
      value: value,
      categoryName: json['categoryName']?.toString(),
      isSensitive: json['isSensitive'] == true,
    );
  }
}

enum NearbySendResult {
  accepted,
  rejected,
  unreachable,
  timeout,
  cancelled,
  disabled,
  error,
}

class NearbySendReport {
  const NearbySendReport(this.result, {this.message});
  final NearbySendResult result;
  final String? message;
}
