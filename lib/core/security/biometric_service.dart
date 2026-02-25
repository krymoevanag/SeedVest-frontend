import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();
      return (canCheck || isSupported) && available.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  Future<String> biometricLabel() async {
    try {
      final available = await _localAuth.getAvailableBiometrics();
      if (available.contains(BiometricType.face)) {
        return 'Face Unlock';
      }
      if (available.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      }
      if (available.contains(BiometricType.strong)) {
        return 'Biometrics';
      }
    } on PlatformException {
      // Fallback label below.
    }
    return 'Biometrics';
  }

  Future<bool> authenticate({
    String reason = 'Authenticate to continue',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
