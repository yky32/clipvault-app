/// Nearby (LAN) vault item transfer — LocalSend-inspired.
///
/// Protocol v2 (HTTP on local Wi‑Fi, no ClipVal cloud):
/// - Advertise: Bonjour `_clipval-nearby._tcp`
/// - GET  /v1/ping  → device card (`pinRequired: true`, no PIN leak)
/// - POST /v1/offer → PIN required; **value is AES-GCM ciphertext**
/// - Holds until receiver Accept/Reject (timeout ~55s)
///
/// Trust: same LAN + 6-digit session PIN (shown on receiver) + human Accept.
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

/// Wire payload for POST /v1/offer (v2).
class NearbyOfferWire {
  const NearbyOfferWire({
    required this.fromName,
    required this.fromId,
    required this.title,
    required this.pin,
    required this.ciphertext,
    required this.nonce,
    required this.mac,
    this.categoryName,
    this.isSensitive = false,
    this.protocolVersion = 2,
  });

  final int protocolVersion;
  final String fromName;
  final String fromId;
  final String title;
  final String pin;
  final String ciphertext;
  final String nonce;
  final String mac;
  final String? categoryName;
  final bool isSensitive;

  Map<String, dynamic> toJson() => {
        'protocolVersion': protocolVersion,
        'fromName': fromName,
        'fromId': fromId,
        'title': title,
        'pin': pin,
        'ciphertext': ciphertext,
        'nonce': nonce,
        'mac': mac,
        if (categoryName != null && categoryName!.isNotEmpty)
          'categoryName': categoryName,
        'isSensitive': isSensitive,
      };

  static NearbyOfferWire? tryParse(Map<String, dynamic> json) {
    final title = json['title']?.toString() ?? '';
    final pin = json['pin']?.toString() ?? '';
    final ct = json['ciphertext']?.toString() ?? '';
    final nonce = json['nonce']?.toString() ?? '';
    final mac = json['mac']?.toString() ?? '';
    // v1 plaintext fallback rejected — force v2 crypto.
    if (ct.isEmpty || nonce.isEmpty || mac.isEmpty) return null;
    if (title.trim().isEmpty) return null;
    return NearbyOfferWire(
      protocolVersion: (json['protocolVersion'] as num?)?.toInt() ?? 2,
      fromName: json['fromName']?.toString() ?? 'ClipVal',
      fromId: json['fromId']?.toString() ?? '',
      title: title.trim(),
      pin: pin,
      ciphertext: ct,
      nonce: nonce,
      mac: mac,
      categoryName: json['categoryName']?.toString(),
      isSensitive: json['isSensitive'] == true,
    );
  }
}

/// Decrypted offer for UI.
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
}

enum NearbySendResult {
  accepted,
  rejected,
  unreachable,
  timeout,
  cancelled,
  disabled,
  badPin,
  error,
}

class NearbySendReport {
  const NearbySendReport(this.result, {this.message});
  final NearbySendResult result;
  final String? message;
}
