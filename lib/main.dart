import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/utils/app.dart';
import 'package:pomodoro/utils/notifications/notifications.dart';

void main() async {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  // Migrar datos antiguos una vez
  await SessionRepository().migrateLegacyIfNeeded();

  // Initialize Firebase (using default options or generated options if provided)
  try {
    await Firebase.initializeApp();
    // If using generated options (recommended – adds proper platform config):
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    // If this fires you likely have not added google-services.json / GoogleService-Info.plist
    // or not generated firebase_options.dart via `flutterfire configure`.
    // We log and allow the app to continue in "local-only" mode.
    debugPrint('Firebase initialization failed -> $e');
    debugPrint('$st');
  }

  runApp(MyApp(navigatorKey: navigatorKey));
}
