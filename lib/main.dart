import 'package:flutter/material.dart';

import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/utils/app.dart';
import 'package:pomodoro/utils/notifications/notifications.dart';
import 'package:pomodoro/core/theme/theme_controller.dart';

void main() async {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  // Migrar datos antiguos una vez
  await SessionRepository().migrateLegacyIfNeeded();
  // Cargar preferencia de tema (oscuro por defecto si no existe)
  await ThemeController.instance.load();

  // Firebase disabled for now. To re-enable, uncomment initialization above and
  // ensure platform options (google-services.json / GoogleService-Info.plist) are provided.
  // TODO: On re-enable, consider wrapping `Firebase.initializeApp()` with
  // a timeout and handle missing `firebase_options.dart`. Example steps:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Also update CI/mobile release builds to include platform config files.

  runApp(MyApp(navigatorKey: navigatorKey));
}
