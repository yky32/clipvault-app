import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Password-protected ClipVal backup (`.clipval`).
///
/// Wraps the plain CSV migration payload with PBKDF2-SHA256 + AES-256-GCM.
/// Device Keychain keys are never used — restore works on a new phone.
abstract final class VaultBackup {
  static const formatId = 'clipval_backup';
  static const formatVersion = 1;
  static const kdfId = 'pbkdf2-sha256';
  static const cipherId = 'aes-256-gcm';

  /// OWASP 2023 recommendation for PBKDF2-HMAC-SHA256.
  static const defaultIterations = 310000;
  static const saltLength = 16;
  static const nonceLength = 12;
  static const keyLength = 32;
  static const macBitSize = 128;
  static const minPasswordLength = 8;

  /// True if [bytes] look like a ClipVal encrypted backup (not CSV).
  static bool looksLikeBackup(List<int> bytes) {
    try {
      final map = _parseEnvelope(bytes);
      return map['format'] == formatId;
    } catch (_) {
      return false;
    }
  }

  /// Encrypt [csv] under [password]. Returns UTF-8 JSON envelope bytes.
  static Uint8List encode({
    required String csv,
    required String password,
    int iterations = defaultIterations,
    Random? random,
  }) {
    final pw = password;
    if (pw.length < minPasswordLength) {
      throw ArgumentError(
        'Password must be at least $minPasswordLength characters',
      );
    }

    final rng = random ?? Random.secure();
    final salt = _randomBytes(rng, saltLength);
    final nonce = _randomBytes(rng, nonceLength);
    final key = _deriveKey(password: pw, salt: salt, iterations: iterations);
    final plaintext = Uint8List.fromList(utf8.encode(csv));
    final ciphertext = _aesGcm(
      encrypt: true,
      key: key,
      nonce: nonce,
      data: plaintext,
    );

    final envelope = <String, Object>{
      'format': formatId,
      'version': formatVersion,
      'kdf': kdfId,
      'iterations': iterations,
      'salt': base64Encode(salt),
      'cipher': cipherId,
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(ciphertext),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(envelope)),
    );
  }

  /// Decrypt a `.clipval` envelope to the inner CSV string.
  ///
  /// Throws [VaultBackupWrongPasswordException] if the password is wrong or
  /// the ciphertext was tampered with. Throws [VaultBackupFormatException]
  /// for unreadable files.
  static String decode({
    required List<int> bytes,
    required String password,
  }) {
    final map = _parseEnvelope(bytes);

    if (map['format'] != formatId) {
      throw const VaultBackupFormatException('Not a ClipVal backup file');
    }
    final version = map['version'];
    if (version is! int || version < 1 || version > formatVersion) {
      throw VaultBackupFormatException('Unsupported backup version: $version');
    }
    if (map['kdf'] != kdfId || map['cipher'] != cipherId) {
      throw const VaultBackupFormatException('Unsupported crypto parameters');
    }

    final iterationsRaw = map['iterations'];
    final iterations = iterationsRaw is int
        ? iterationsRaw
        : (iterationsRaw is num ? iterationsRaw.toInt() : null);
    // Floor is intentionally low so unit tests can use fewer rounds;
    // production encodes with [defaultIterations].
    if (iterations == null || iterations < 1000) {
      throw const VaultBackupFormatException('Invalid KDF iterations');
    }

    late final Uint8List salt;
    late final Uint8List nonce;
    late final Uint8List ciphertext;
    try {
      salt = base64Decode(map['salt'] as String);
      nonce = base64Decode(map['nonce'] as String);
      ciphertext = base64Decode(map['ciphertext'] as String);
    } catch (_) {
      throw const VaultBackupFormatException('Corrupt backup fields');
    }

    if (salt.length < 8 || nonce.length != nonceLength || ciphertext.isEmpty) {
      throw const VaultBackupFormatException('Invalid salt/nonce/ciphertext');
    }

    final key = _deriveKey(
      password: password,
      salt: salt,
      iterations: iterations,
    );

    try {
      final plain = _aesGcm(
        encrypt: false,
        key: key,
        nonce: nonce,
        data: ciphertext,
      );
      return utf8.decode(plain);
    } catch (_) {
      throw const VaultBackupWrongPasswordException();
    }
  }

  static Map<String, dynamic> _parseEnvelope(List<int> bytes) {
    if (bytes.isEmpty) {
      throw const VaultBackupFormatException('Empty file');
    }
    try {
      final text = utf8.decode(bytes);
      final trimmed = text.trimLeft();
      if (!trimmed.startsWith('{')) {
        throw const VaultBackupFormatException('Not a JSON backup');
      }
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const VaultBackupFormatException('Invalid backup root');
      }
      return Map<String, dynamic>.from(decoded);
    } on VaultBackupFormatException {
      rethrow;
    } catch (_) {
      throw const VaultBackupFormatException('Could not parse backup file');
    }
  }

  static Uint8List _deriveKey({
    required String password,
    required Uint8List salt,
    required int iterations,
  }) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, keyLength));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List _aesGcm({
    required bool encrypt,
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List data,
  }) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        encrypt,
        AEADParameters(KeyParameter(key), macBitSize, nonce, Uint8List(0)),
      );
    return cipher.process(data);
  }

  static Uint8List _randomBytes(Random rng, int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }
}

class VaultBackupFormatException implements Exception {
  const VaultBackupFormatException([this.message = 'Invalid backup file']);
  final String message;

  @override
  String toString() => 'VaultBackupFormatException: $message';
}

class VaultBackupWrongPasswordException implements Exception {
  const VaultBackupWrongPasswordException([
    this.message = 'Wrong password or corrupted backup',
  ]);
  final String message;

  @override
  String toString() => 'VaultBackupWrongPasswordException: $message';
}
