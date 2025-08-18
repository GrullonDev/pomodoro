// Firebase auth temporarily disabled to avoid exceptions when Firebase is not configured.
// TODO: Re-enable Firebase Auth when ready:
//  - Restore imports for `firebase_core` and `firebase_auth`.
//  - Ensure `Firebase.initializeApp()` runs in `main.dart` before using Auth.
//  - Update types back to `User`/`FirebaseAuth` and re-enable `_safeAuth` logic.
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pomodoro/core/auth/auth_service.dart';

class AuthRepository {
  // Delegate to AuthService (which provides Firebase or local fallback behavior)

  Stream<dynamic> get userChanges => AuthService.instance.uidChanges();

  dynamic get currentUser => null; // features relying on full Firebase User should be migrated

  Future<dynamic> signInWithEmail(String email, String password) async {
    return await AuthService.instance.signInWithEmail(email, password);
  }

  Future<dynamic> registerWithEmail(String email, String password) async {
    return await AuthService.instance.registerWithEmail(email, password);
  }

  Future<dynamic> signInWithGoogle() async {
    // For now, try GoogleSignIn as a best-effort placeholder; real Firebase credential flow
    // should be implemented when enabling Firebase.
    try {
      final gs = await GoogleSignIn().signIn();
      if (gs == null) throw StateError('Google sign-in canceled');
      // No Firebase linking performed here; signal success by returning account info.
      return gs;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithPhone(String phoneNumber) async {
    // Phone auth not implemented at feature level yet.
    throw UnimplementedError('Phone sign-in not implemented');
  }

  Future<void> signOut() async {
    return await AuthService.instance.signOut();
  }

  /// Expose a helper to check sign-in methods for an email (delegates to AuthService).
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    try {
      return await AuthService.instance.fetchSignInMethodsForEmail(email);
    } catch (_) {
      return [];
    }
  }
}
