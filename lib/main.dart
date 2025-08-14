import 'package:flutter/material.dart';

// Firebase temporarily disabled to avoid startup exceptions when not configured.
// TODO: Re-enable Firebase when ready —
// 1) Add platform config files (android: google-services.json, iOS: GoogleService-Info.plist)
// 2) Run `flutterfire configure` to generate `firebase_options.dart` (recommended)
// 3) Uncomment the import below and the initialization block further down.
// import 'package:firebase_core/firebase_core.dart';

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

  // Firebase disabled for now. To re-enable, uncomment initialization above and
  // ensure platform options (google-services.json / GoogleService-Info.plist) are provided.
  // TODO: On re-enable, consider wrapping `Firebase.initializeApp()` with
  // a timeout and handle missing `firebase_options.dart`. Example steps:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Also update CI/mobile release builds to include platform config files.

  runApp(MyApp(navigatorKey: navigatorKey));
}
