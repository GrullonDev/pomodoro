import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> get isBiometricsAvailable async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final available = await isBiometricsAvailable;
      if (!available) return false;

      return await _auth.authenticate(
        localizedReason: 'Por favor autentíquese para acceder',
        biometricOnly: true,
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}
