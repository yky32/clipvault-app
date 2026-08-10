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

  /// In-memory key only — for unit tests (no secure storage).
  EncryptionService.forTest([List<int>? keyBytes]) : _storage = null {
    final bytes =
        keyBytes ?? List<int>.generate(32, (i) => (i * 17 + 3) % 256);
    final raw = base64Encode(bytes);
    _key = encrypt.Key.fromBase64(raw);
    final ivBytes = encrypt.Key.fromBase64(raw).bytes.sublist(0, 16);
    _iv = encrypt.IV(ivBytes);
  }

  final FlutterSecureStorage? _storage;
  encrypt.Key? _key;
  encrypt.IV? _iv;

  Future<void> init() async {
    if (_key != null && _iv != null) return;
    final storage = _storage;
    if (storage == null) {
      throw StateError('EncryptionService.forTest is already initialized');
    }
    var raw = await storage.read(key: AppConstants.encryptionKeyName);
    if (raw == null) {
      final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      raw = base64Encode(bytes);
      await storage.write(key: AppConstants.encryptionKeyName, value: raw);
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

  /// Base64 AES-256 key for CloudKit VaultMeta (Phase E).
  /// Never log this. Only leaves the device via the user’s private iCloud.
  String exportKeyBase64() {
    final key = _key;
    if (key == null) {
      throw StateError('EncryptionService not initialized');
    }
    return base64Encode(key.bytes);
  }

  /// Replace the master key (e.g. adopt remote iCloud key) and re-encrypt
  /// every item value under the new key. [reencryptItems] decrypts with the
  /// old key and returns plaintexts that are saved under the new key.
  Future<void> replaceKeyAndReencrypt({
    required String newKeyBase64,
    required Future<void> Function(
      String Function(String ciphertext) decryptWithOld,
      String Function(String plaintext) encryptWithNew,
    ) reencryptItems,
  }) async {
    final storage = _storage;
    if (storage == null) {
      throw StateError('Cannot replace key in test EncryptionService');
    }
    final oldKey = _key;
    final oldIv = _iv;
    if (oldKey == null || oldIv == null) {
      throw StateError('EncryptionService not initialized');
    }

    String decryptOld(String ciphertext) {
      final encrypter = encrypt.Encrypter(
        encrypt.AES(oldKey, mode: encrypt.AESMode.cbc),
      );
      return encrypter.decrypt64(ciphertext, iv: oldIv);
    }

    final newKey = encrypt.Key.fromBase64(newKeyBase64);
    final newIv = encrypt.IV(newKey.bytes.sublist(0, 16));

    String encryptNew(String plaintext) {
      final encrypter = encrypt.Encrypter(
        encrypt.AES(newKey, mode: encrypt.AESMode.cbc),
      );
      return encrypter.encrypt(plaintext, iv: newIv).base64;
    }

    await reencryptItems(decryptOld, encryptNew);

    await storage.write(key: AppConstants.encryptionKeyName, value: newKeyBase64);
    _key = newKey;
    _iv = newIv;
  }

  /// Install a key when local vault is empty (second device first sync).
  Future<void> installKeyBase64(String keyBase64) async {
    final storage = _storage;
    if (storage == null) {
      throw StateError('Cannot install key in test EncryptionService');
    }
    await storage.write(key: AppConstants.encryptionKeyName, value: keyBase64);
    _key = encrypt.Key.fromBase64(keyBase64);
    _iv = encrypt.IV(_key!.bytes.sublist(0, 16));
  }
}
