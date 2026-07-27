import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'settings_service.dart';

/// Preferred unlock method for UI (icon / hint on lock screen).
enum UnlockBiometricKind {
  faceId,
  touchId,
  fingerprint,
  strongBiometric,
  devicePasscode,
}

class AuthService {
  AuthService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Best-effort biometric type for lock UI (Face ID / Touch ID / lock).
  Future<UnlockBiometricKind> preferredUnlockKind() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return UnlockBiometricKind.devicePasscode;

      final types = await _localAuth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) {
        return UnlockBiometricKind.faceId;
      }
      if (types.contains(BiometricType.fingerprint)) {
        // iOS Touch ID reports as fingerprint; Android fingerprint too.
        return UnlockBiometricKind.touchId;
      }
      if (types.contains(BiometricType.strong) ||
          types.contains(BiometricType.weak)) {
        return UnlockBiometricKind.strongBiometric;
      }
      if (types.contains(BiometricType.iris)) {
        return UnlockBiometricKind.faceId;
      }
      return UnlockBiometricKind.devicePasscode;
    } on PlatformException {
      return UnlockBiometricKind.devicePasscode;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      // Prefer biometrics when available; still allow device passcode fallback.
      // Keep [localizedReason] short — the OS sheet cannot be restyled.
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  bool get requiresUnlock => SettingsService.instance.biometricLockEnabled;
}
