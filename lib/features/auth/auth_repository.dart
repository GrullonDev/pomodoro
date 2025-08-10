import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  FirebaseAuth? _auth; // lazily set when Firebase initialized

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  FirebaseAuth? get _safeAuth {
    if (!_isFirebaseReady) return null;
    return _auth ??= FirebaseAuth.instance;
  }

  Stream<User?> get userChanges {
    final auth = _safeAuth;
    if (auth == null) {
      // Emit single null then complete to avoid rebuild storms.
      return Stream<User?>.value(null);
    }
    return auth.authStateChanges();
  }

  User? get currentUser => _safeAuth?.currentUser;

  Future<User?> signInWithEmail(String email, String password) async {
    final auth = _safeAuth;
    if (auth == null) {
      throw StateError('Firebase not initialized');
    }
    final cred = await auth.signInWithEmailAndPassword(
        email: email, password: password);
    return cred.user;
  }

  Future<User?> registerWithEmail(String email, String password) async {
    final auth = _safeAuth;
    if (auth == null) {
      throw StateError('Firebase not initialized');
    }
    final cred = await auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return cred.user;
  }

  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final auth = _safeAuth;
    if (auth == null) {
      throw StateError('Firebase not initialized');
    }
    final userCred = await auth.signInWithCredential(credential);
    return userCred.user;
  }

  // Placeholder phone auth start; needs real verification flow (SMS) for production.
  Future<void> signInWithPhone(String phoneNumber) async {
    // TODO: Implement full phone auth; here we just throw to indicate not implemented.
    throw UnimplementedError('Phone sign-in not implemented');
  }

  Future<void> signOut() async {
    final auth = _safeAuth;
    if (auth == null) {
      debugPrint('signOut called but Firebase not initialized');
      return;
    }
    await auth.signOut();
    // GoogleSignIn signOut is safe even if user never signed in.
    await GoogleSignIn().signOut();
  }
}
