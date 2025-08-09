import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package.flutter_riverpod/flutter_riverpod.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      if (canAuthenticate) {
        final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty) {
          return true;
        }
      }
    } on PlatformException catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> authenticate(String localizedReason) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print(e);
      return false;
    }
  }
}
