import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'settings_service.dart';

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
