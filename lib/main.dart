import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/di/injection.dart';
import 'package:pomodoro/core/theme/theme_controller.dart';
import 'package:pomodoro/utils/app.dart';
import 'package:pomodoro/utils/notifications/notifications.dart';

void main() async {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  WidgetsFlutterBinding.ensureInitialized();
  // Initialize dependency injection
  await init();

  // Initialize Firebase. If platform config files (google-services.json /
  // GoogleService-Info.plist) are present this will succeed; otherwise we
  // catch and continue so the app can still run locally.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Initialization may fail on web if firebase_options.dart isn't provided
    // or on misconfigured platforms. Log and continue; authentication calls
    // should be guarded by error handling in the AuthService.
    // ignore: avoid_print
    print('Firebase.initializeApp() failed: $e');
  }

  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  // Migrar datos antiguos una vez
  await SessionRepository().migrateLegacyIfNeeded();
  // Cargar preferencia de tema (oscuro por defecto si no existe)
  await ThemeController.instance.load();

  runApp(MyApp(navigatorKey: navigatorKey));
}
