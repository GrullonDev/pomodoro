import 'package:flutter/material.dart';

import 'package:pomodoro/utils/app.dart';
import 'package:pomodoro/utils/notifications/notifications.dart';
import 'package:pomodoro/core/data/session_repository.dart';

void main() async {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize(); // Ya no pasa context
  await NotificationService.requestPermissions();
  // Migrar datos antiguos una vez
  await SessionRepository().migrateLegacyIfNeeded();

  runApp(MyApp(navigatorKey: navigatorKey));
}
