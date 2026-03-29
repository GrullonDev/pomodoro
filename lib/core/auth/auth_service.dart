import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Central auth service backed exclusively by Firebase Auth.
/// Supports anonymous (guest) accounts, Google, Apple, and email/password.
/// Anonymous accounts are seamlessly linked to a real account when the user
/// decides to "save their progress" — the uid is preserved so all local data
/// remains intact.
class AuthService {
  AuthService._internal();
  static final instance = AuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  // ──────────────────────────────────────────────────────────────────────────
  // State / streams
  // ──────────────────────────────────────────────────────────────────────────

  /// Emits the current uid whenever auth state changes (null = signed out).
  Stream<String?> uidChanges() =>
      _auth.authStateChanges().map((u) => u?.uid);

  /// Current uid, or null if not signed in / not yet initialized.
  Future<String?> currentUid() async {
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// True when the current user is an anonymous (guest) account.
  bool get isGuest => _auth.currentUser?.isAnonymous ?? true;

  // ──────────────────────────────────────────────────────────────────────────
  // Guest mode
  // ──────────────────────────────────────────────────────────────────────────

  /// Signs in anonymously.  No-op if a user session already exists.
  Future<void> signInAnonymously() async {
    if (_auth.currentUser != null) return;
    await _auth.signInAnonymously();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Email / password
  // ──────────────────────────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmail(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  /// Creates a new email/password account.
  /// If the current session is anonymous, the anonymous account is linked to
  /// the new credential so the uid (and all existing data) is preserved.
  Future<UserCredential> registerWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    UserCredential cred;
    final emailCred =
        EmailAuthProvider.credential(email: email, password: password);

    if (_auth.currentUser?.isAnonymous == true) {
      cred = await _auth.currentUser!.linkWithCredential(emailCred);
    } else {
      cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    }
    if (name != null && name.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(name.trim());
    }
    return cred;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Google
  // ──────────────────────────────────────────────────────────────────────────

  /// Signs in with Google.
  /// Links the anonymous account when the current session is a guest, so the
  /// uid and all existing data are preserved.
  Future<UserCredential> signInWithGoogle() async {
    // Let the plugin auto-detect serverClientId from google-services.json
    // (via the generated default_web_client_id string resource).
    final googleSignIn = GoogleSignIn(scopes: ['email']);

    // Ensure any stale session is cleared before attempting sign-in
    try {
      await googleSignIn.signOut();
    } catch (_) {}

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw StateError('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    if (_auth.currentUser?.isAnonymous == true) {
      return await _auth.currentUser!.linkWithCredential(credential);
    }
    return await _auth.signInWithCredential(credential);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Apple
  // ──────────────────────────────────────────────────────────────────────────

  /// Signs in with Apple (iOS / macOS only).
  /// Links the anonymous account when the current session is a guest.
  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    if (_auth.currentUser?.isAnonymous == true) {
      return await _auth.currentUser!.linkWithCredential(oauthCredential);
    }
    return await _auth.signInWithCredential(oauthCredential);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Profile helpers
  // ──────────────────────────────────────────────────────────────────────────

  Future<Map<String, String?>> currentProfile() async {
    final u = _auth.currentUser;
    return {
      'uid': u?.uid,
      'email': u?.email,
      'name': u?.displayName,
      'isGuest': (u?.isAnonymous ?? true) ? 'true' : 'false',
    };
  }

  Future<void> updateDisplayName(String name) async {
    if (name.trim().isEmpty) return;
    await _auth.currentUser?.updateDisplayName(name.trim());
  }

  Future<String?> updatePassword(
    String newPassword, {
    String? currentPassword,
  }) async {
    if (newPassword.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      return null;
    } catch (e) {
      return 'No se pudo actualizar: $e';
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sign out
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
