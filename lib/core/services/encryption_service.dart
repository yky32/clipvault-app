import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// AES-256 encryption for values at rest (PRD §5.3).
class EncryptionService {
  EncryptionService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;
  encrypt.Key? _key;
  encrypt.IV? _iv;

  Future<void> init() async {
    var raw = await _storage.read(key: AppConstants.encryptionKeyName);
    if (raw == null) {
      final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      raw = base64Encode(bytes);
      await _storage.write(key: AppConstants.encryptionKeyName, value: raw);
    }
    _key = encrypt.Key.fromBase64(raw);
    // Deterministic IV derived from key for stable storage (key never leaves secure storage).
    final ivBytes = encrypt.Key.fromBase64(raw).bytes.sublist(0, 16);
    _iv = encrypt.IV(ivBytes);
  }

  String encryptText(String plaintext) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
    );
    return encrypter.encrypt(plaintext, iv: _iv!).base64;
  }

  String decryptText(String ciphertext) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
    );
    return encrypter.decrypt64(ciphertext, iv: _iv!);
  }
}
