import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Nearby protocol helpers — PIN session + AES-CBC + HMAC (v2).
class NearbyCrypto {
  NearbyCrypto._();

  static const protocolVersion = 2;
  static const _kdfPrefix = 'clipval-nearby-v2';

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

  static Uint8List _keyBytes({
    required String pin,
    required String receiverDeviceId,
  }) {
    final material = utf8.encode('$_kdfPrefix|$pin|$receiverDeviceId');
    return Uint8List.fromList(sha256.convert(material).bytes);
  }

  static ({String ciphertext, String nonce, String mac}) encryptValue({
    required String value,
    required String pin,
    required String receiverDeviceId,
  }) {
    final keyBytes = _keyBytes(pin: pin, receiverDeviceId: receiverDeviceId);
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(value, iv: iv);
    final mac = Hmac(sha256, keyBytes)
        .convert(iv.bytes + encrypted.bytes)
        .bytes;
    return (
      ciphertext: encrypted.base64,
      nonce: iv.base64,
      mac: base64Encode(mac),
    );
  }

  static String? decryptValue({
    required String ciphertext,
    required String nonce,
    required String pin,
    required String receiverDeviceId,
    String? mac,
  }) {
    try {
      final keyBytes = _keyBytes(pin: pin, receiverDeviceId: receiverDeviceId);
      final key = enc.Key(keyBytes);
      final iv = enc.IV.fromBase64(nonce);
      final encrypted = enc.Encrypted.fromBase64(ciphertext);

      if (mac != null && mac.isNotEmpty) {
        final expected = Hmac(sha256, keyBytes)
            .convert(iv.bytes + encrypted.bytes)
            .bytes;
        final got = base64Decode(mac);
        if (expected.length != got.length) return null;
        var diff = 0;
        for (var i = 0; i < expected.length; i++) {
          diff |= expected[i] ^ got[i];
        }
        if (diff != 0) return null;
      }

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      return null;
    }
  }

  static String clipboardFingerprint(String text) {
    return sha256.convert(utf8.encode('clipval-cb|$text')).toString();
  }
}
