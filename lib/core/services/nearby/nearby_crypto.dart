import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Nearby protocol helpers — PIN session + AES-GCM payload (v2).
class NearbyCrypto {
  NearbyCrypto._();

  static const protocolVersion = 2;
  static const _kdfPrefix = 'clipval-nearby-v2';

  /// 6-digit PIN, never 000000.
  static String generatePin([Random? random]) {
    final r = random ?? Random.secure();
    final n = r.nextInt(1000000);
    if (n == 0) return '100000';
    return n.toString().padLeft(6, '0');
  }

  static bool isValidPin(String? pin) {
    if (pin == null) return false;
    return RegExp(r'^\d{6}$').hasMatch(pin);
  }

  static enc.Key keyFor({
    required String pin,
    required String receiverDeviceId,
  }) {
    final material = utf8.encode('$_kdfPrefix|$pin|$receiverDeviceId');
    final digest = sha256.convert(material);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypt UTF-8 value → base64 ciphertext + base64 nonce.
  static ({String ciphertext, String nonce}) encryptValue({
    required String value,
    required String pin,
    required String receiverDeviceId,
  }) {
    final key = keyFor(pin: pin, receiverDeviceId: receiverDeviceId);
    final iv = enc.IV.fromSecureRandom(12);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm, padding: null));
    final encrypted = encrypter.encryptBytes(utf8.encode(value), iv: iv);
    return (ciphertext: encrypted.base64, nonce: iv.base64);
  }

  static String? decryptValue({
    required String ciphertext,
    required String nonce,
    required String pin,
    required String receiverDeviceId,
  }) {
    try {
      final key = keyFor(pin: pin, receiverDeviceId: receiverDeviceId);
      final iv = enc.IV.fromBase64(nonce);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm, padding: null));
      final bytes = encrypter.decryptBytes(enc.Encrypted.fromBase64(ciphertext), iv: iv);
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Privacy: store hash of dismissed clipboard, not plaintext.
  static String clipboardFingerprint(String text) {
    return sha256.convert(utf8.encode('clipval-cb|$text')).toString();
  }
}
