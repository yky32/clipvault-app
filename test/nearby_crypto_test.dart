import 'package:flutter_test/flutter_test.dart';
import 'package:clipval/core/services/nearby/nearby_crypto.dart';

void main() {
  test('PIN generate is 6 digits', () {
    for (var i = 0; i < 20; i++) {
      final p = NearbyCrypto.generatePin();
      expect(NearbyCrypto.isValidPin(p), isTrue);
    }
  });

  test('encrypt/decrypt round-trip with PIN + device id', () {
    const pin = '482913';
    const deviceId = 'device-abc';
    const plain = 'super-secret-api-key-xyz';
    final sealed = NearbyCrypto.encryptValue(
      value: plain,
      pin: pin,
      receiverDeviceId: deviceId,
    );
    expect(sealed.ciphertext, isNot(contains(plain)));
    final out = NearbyCrypto.decryptValue(
      ciphertext: sealed.ciphertext,
      nonce: sealed.nonce,
      pin: pin,
      receiverDeviceId: deviceId,
    );
    expect(out, plain);
  });

  test('wrong PIN fails decrypt', () {
    final sealed = NearbyCrypto.encryptValue(
      value: 'hello',
      pin: '111111',
      receiverDeviceId: 'd1',
    );
    final out = NearbyCrypto.decryptValue(
      ciphertext: sealed.ciphertext,
      nonce: sealed.nonce,
      pin: '222222',
      receiverDeviceId: 'd1',
    );
    expect(out, isNull);
  });

  test('clipboard fingerprint is stable and not plaintext', () {
    final a = NearbyCrypto.clipboardFingerprint('wifi-password');
    final b = NearbyCrypto.clipboardFingerprint('wifi-password');
    expect(a, b);
    expect(a.contains('wifi'), isFalse);
    expect(a.length, 64);
  });
}
