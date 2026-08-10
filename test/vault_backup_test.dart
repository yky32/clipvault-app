import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:clipval/core/services/vault_backup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Faster KDF in tests only — production uses defaultIterations.
  const testIterations = 1000;

  group('VaultBackup', () {
    test('round-trips CSV under password', () {
      const csv = '''
# clipval_export_version=1
title,value,category_name,category_system_key,language,pinned,created_at,updated_at,last_copied_at
Wi-Fi,secret123,Wi-Fi,wifi,,false,,,
''';
      final bytes = VaultBackup.encode(
        csv: csv,
        password: 'correct-horse',
        iterations: testIterations,
        random: Random(42),
      );

      expect(VaultBackup.looksLikeBackup(bytes), isTrue);
      final decoded = VaultBackup.decode(
        bytes: bytes,
        password: 'correct-horse',
      );
      expect(decoded, csv);

      final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      expect(envelope['format'], VaultBackup.formatId);
      expect(envelope['version'], VaultBackup.formatVersion);
      expect(envelope['kdf'], VaultBackup.kdfId);
      expect(envelope['cipher'], VaultBackup.cipherId);
      expect(envelope['iterations'], testIterations);
    });

    test('wrong password throws', () {
      final bytes = VaultBackup.encode(
        csv: 'title,value\nA,1\n',
        password: 'right-password',
        iterations: testIterations,
        random: Random(7),
      );

      expect(
        () => VaultBackup.decode(bytes: bytes, password: 'wrong-password'),
        throwsA(isA<VaultBackupWrongPasswordException>()),
      );
    });

    test('tampered ciphertext throws wrong-password', () {
      final bytes = VaultBackup.encode(
        csv: 'title,value\nA,1\n',
        password: 'right-password',
        iterations: testIterations,
        random: Random(9),
      );
      final map = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(bytes)) as Map,
      );
      final ct = base64Decode(map['ciphertext'] as String);
      ct[0] = ct[0] ^ 0xff;
      map['ciphertext'] = base64Encode(ct);
      final tampered = Uint8List.fromList(utf8.encode(jsonEncode(map)));

      expect(
        () => VaultBackup.decode(
          bytes: tampered,
          password: 'right-password',
        ),
        throwsA(isA<VaultBackupWrongPasswordException>()),
      );
    });

    test('plain CSV is not a backup', () {
      final csv = utf8.encode('# clipval_export_version=1\ntitle,value\n');
      expect(VaultBackup.looksLikeBackup(csv), isFalse);
    });

    test('rejects short password on encode', () {
      expect(
        () => VaultBackup.encode(csv: 'x', password: 'short'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invalid envelope', () {
      expect(
        () => VaultBackup.decode(
          bytes: utf8.encode('{"format":"nope"}'),
          password: 'anything1',
        ),
        throwsA(isA<VaultBackupFormatException>()),
      );
    });
  });
}
