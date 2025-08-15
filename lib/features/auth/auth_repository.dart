// Firebase auth temporarily disabled to avoid exceptions when Firebase is not configured.
// TODO: Re-enable Firebase Auth when ready:
//  - Restore imports for `firebase_core` and `firebase_auth`.
//  - Ensure `Firebase.initializeApp()` runs in `main.dart` before using Auth.
//  - Update types back to `User`/`FirebaseAuth` and re-enable `_safeAuth` logic.
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  // FirebaseAuth? _auth; // lazily set when Firebase initialized

  // bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  // FirebaseAuth? get _safeAuth {
  //   if (!_isFirebaseReady) return null;
  //   return _auth ??= FirebaseAuth.instance;
  // }
  // TODO: When re-enabling, uncomment the above and remove stubs below.

  // Stream<User?> get userChanges {
  // Firebase disabled; provide a lightweight stub for code that depends on this.
  // TODO: replace stub with actual `Stream<User?>` and `currentUser` when enabling Auth.
  Stream<dynamic> get userChanges => Stream<dynamic>.value(null);

  dynamic get currentUser => null;

  Future<dynamic> signInWithEmail(String email, String password) async {
    // Firebase sign-in disabled in this build.
    // TODO: implement by restoring `_safeAuth` and calling `signInWithEmailAndPassword`.
    throw StateError('Firebase disabled in this build');
  }

  Future<dynamic> registerWithEmail(String email, String password) async {
    // Firebase registration disabled in this build.
    // TODO: implement by restoring `_safeAuth` and calling `createUserWithEmailAndPassword`.
    throw StateError('Firebase disabled in this build');
  }

  Future<dynamic> signInWithGoogle() async {
    // Firebase social sign-in disabled in this build.
    // TODO: implement by restoring Google credential flow and `_safeAuth.signInWithCredential`.
    throw StateError('Firebase disabled in this build');
  }

  // Placeholder phone auth start; needs real verification flow (SMS) for production.
  Future<void> signInWithPhone(String phoneNumber) async {
    // TODO: Implement full phone auth; here we just throw to indicate not implemented.
    throw UnimplementedError('Phone sign-in not implemented');
  }

  Future<void> signOut() async {
    // No-op sign-out while Firebase is disabled.
    // TODO: when enabling, call `_safeAuth?.signOut()` and preserve GoogleSignIn signOut.
    debugPrint('signOut called but Firebase disabled in this build');
    await GoogleSignIn().signOut();
  }
}
