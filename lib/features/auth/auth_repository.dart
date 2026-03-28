import 'package:pomodoro/core/auth/auth_service.dart';
import 'package:pomodoro/core/auth/biometric_service.dart';

class AuthRepository {
  Stream<String?> get userChanges => AuthService.instance.uidChanges();

  bool get isGuest => AuthService.instance.isGuest;

  Future<void> signInAnonymously() => AuthService.instance.signInAnonymously();

  Future<dynamic> signInWithEmail(String email, String password) =>
      AuthService.instance.signInWithEmail(email, password);

  Future<dynamic> registerWithEmail(String email, String password,
          {String? name}) =>
      AuthService.instance.registerWithEmail(email, password, name: name);

  Future<dynamic> signInWithGoogle() => AuthService.instance.signInWithGoogle();

  Future<dynamic> signInWithApple() => AuthService.instance.signInWithApple();

  Future<void> signOut() => AuthService.instance.signOut();

  Future<bool> authenticateWithBiometrics() async {
    final bioService = BiometricService();
    if (await bioService.isBiometricsAvailable) {
      return await bioService.authenticate();
    }
    return false;
  }
}
