import 'package:get_it/get_it.dart';
import 'package:pomodoro/features/auth/auth_repository.dart';
import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/auth/auth_service.dart';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;

final sl = GetIt.instance;

/// Initialize app-wide dependencies. Call once during app startup.
Future<void> init() async {
  // Core services
  sl.registerLazySingleton<AuthService>(() => AuthService.instance);

  // Repositories / data
  sl.registerLazySingleton<SessionRepository>(() => SessionRepository());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository());

  // Try to register Firebase instances if available on runtime
  try {
    final fa = FirebaseAuth.instance;
    sl.registerLazySingleton<FirebaseAuth>(() => fa);
  } catch (_) {
    // Firebase not configured; skip registration
  }
  try {
    final fs = FirebaseFirestore.instance;
    sl.registerLazySingleton<FirebaseFirestore>(() => fs);
  } catch (_) {
    // Firestore not available or not configured; skip
  }
}
