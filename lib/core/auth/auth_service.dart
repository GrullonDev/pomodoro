import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, UserCredential;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._internal();
  static final instance = AuthService._internal();

  // Keys for local fallback users
  static const _localUsersKey = 'local_auth_users'; // JSON map email->{pwd,uid}
  static const _localCurrentUidKey = 'local_auth_current_uid';

  final StreamController<String?> _uidController = StreamController<String?>.broadcast();

  Future<bool> get _firebaseAvailable async {
    try {
      // Accessing FirebaseAuth.instance can throw if Firebase not initialized
      FirebaseAuth.instance; // just access
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns current uid (Firebase uid or local uid) or null if none.
  Future<String?> currentUid() async {
    if (await _firebaseAvailable) {
      try {
        return FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {
        return null;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localCurrentUidKey);
  }

  /// Stream of uid changes (null when signed out)
  Stream<String?> uidChanges() {
    // If Firebase is available, forward its authStateChanges mapped to uid.
    final s = StreamController<String?>.broadcast(onListen: () async {
      if (await _firebaseAvailable) {
        FirebaseAuth.instance.authStateChanges().listen((u) {
          _uidController.add(u?.uid);
        });
      } else {
        // Emit current local uid (may be null)
        final prefs = await SharedPreferences.getInstance();
        _uidController.add(prefs.getString(_localCurrentUidKey));
      }
    });
    // Merge internal controller with this controller
    _uidController.stream.listen((v) => s.add(v));
    return s.stream;
  }

  Future<void> _setLocalCurrentUid(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (uid == null) {
      await prefs.remove(_localCurrentUidKey);
    } else {
      await prefs.setString(_localCurrentUidKey, uid);
    }
    _uidController.add(uid);
  }

  // Local helper to load/create users map
  Future<Map<String, Map<String, String>>> _loadLocalUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localUsersKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, Map<String, String>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveLocalUsers(Map<String, Map<String, String>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localUsersKey, jsonEncode(users));
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (await _firebaseAvailable) {
      return await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    }
    // Local fallback
    final users = await _loadLocalUsers();
    final u = users[email.toLowerCase()];
    if (u == null) throw Exception('No such user');
    if (u['pwd'] != base64Encode(utf8.encode(password))) throw Exception('Wrong password');
    final uid = u['uid']!;
    await _setLocalCurrentUid(uid);
    return null;
  }

  Future<UserCredential?> registerWithEmail(String email, String password) async {
    if (await _firebaseAvailable) {
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    }
    final users = await _loadLocalUsers();
    final key = email.toLowerCase();
    if (users.containsKey(key)) throw Exception('User already exists');
    final uid = 'local_${DateTime.now().millisecondsSinceEpoch}';
    users[key] = {'pwd': base64Encode(utf8.encode(password)), 'uid': uid};
    await _saveLocalUsers(users);
    await _setLocalCurrentUid(uid);
    return null;
  }

  Future<void> signOut() async {
    if (await _firebaseAvailable) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      _uidController.add(null);
      return;
    }
    await _setLocalCurrentUid(null);
  }
}
