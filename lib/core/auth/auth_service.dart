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

  Future<UserCredential?> registerWithEmail(String email, String password, {String? name}) async {
    if (await _firebaseAvailable) {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      try {
        if (name != null && name.trim().isNotEmpty) {
          await cred.user?.updateDisplayName(name.trim());
        }
      } catch (_) {}
      return cred;
    }
    final users = await _loadLocalUsers();
    final key = email.toLowerCase();
    if (users.containsKey(key)) throw Exception('User already exists');
    final uid = 'local_${DateTime.now().millisecondsSinceEpoch}';
    users[key] = {
      'pwd': base64Encode(utf8.encode(password)),
      'uid': uid,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      'email': email,
    };
    await _saveLocalUsers(users);
    await _setLocalCurrentUid(uid);
    return null;
  }

  /// Returns a list of sign-in methods for the provided email.
  /// Firebase variant no-op now (deprecated enumeration). Always returns [] for Firebase,
  /// but still reports password method for local fallback storage to preserve prior UI logic if reused.
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    if (await _firebaseAvailable) {
      // Avoid deprecated email enumeration to reduce user data exposure.
      return [];
    }
    final users = await _loadLocalUsers();
    if (users.containsKey(email.toLowerCase())) return ['password'];
    return [];
  }

  // -------- Profile helpers --------

  Future<String?> currentDisplayName() async {
    if (await _firebaseAvailable) {
      try {
        return FirebaseAuth.instance.currentUser?.displayName;
      } catch (_) {
        return null;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_localCurrentUidKey);
    if (uid == null) return null;
    final users = await _loadLocalUsers();
    for (final entry in users.entries) {
      final data = entry.value;
      if (data['uid'] == uid) {
        return data['name'];
      }
    }
    return null;
  }

  Future<Map<String, String?>> currentProfile() async {
    if (await _firebaseAvailable) {
      try {
        final u = FirebaseAuth.instance.currentUser;
        return {
          'uid': u?.uid,
          'email': u?.email,
          'name': u?.displayName,
        };
      } catch (_) {
        return {'uid': null, 'email': null, 'name': null};
      }
    }
    final users = await _loadLocalUsers();
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_localCurrentUidKey);
    if (uid != null) {
      for (final entry in users.entries) {
        final data = entry.value;
        if (data['uid'] == uid) {
          return {
            'uid': uid,
            'email': data['email'] ?? entry.key,
            'name': data['name'],
          };
        }
      }
    }
    return {'uid': null, 'email': null, 'name': null};
  }

  Future<void> updateDisplayName(String name) async {
    if (name.trim().isEmpty) return;
    if (await _firebaseAvailable) {
      try {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(name.trim());
      } catch (_) {}
      return;
    }
    final users = await _loadLocalUsers();
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_localCurrentUidKey);
    if (uid == null) return;
    bool changed = false;
    users.forEach((email, data) {
      if (data['uid'] == uid) {
        data['name'] = name.trim();
        data['email'] ??= email; // ensure stored
        changed = true;
      }
    });
    if (changed) await _saveLocalUsers(users);
  }

  Future<String?> updatePassword(String newPassword, {String? currentPassword}) async {
    if (newPassword.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    if (await _firebaseAvailable) {
      try {
        await FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
        return null;
      } catch (e) {
        return 'No se pudo actualizar la contraseña: $e';
      }
    }
    final users = await _loadLocalUsers();
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_localCurrentUidKey);
    if (uid == null) return 'No autenticado';
    bool changed = false;
    users.forEach((email, data) {
      if (data['uid'] == uid) {
        // Optionally verify current password if provided
        if (currentPassword != null && data['pwd'] != base64Encode(utf8.encode(currentPassword))) {
          changed = false;
          return;
        }
        data['pwd'] = base64Encode(utf8.encode(newPassword));
        changed = true;
      }
    });
    if (!changed) return 'Contraseña actual incorrecta';
    await _saveLocalUsers(users);
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
