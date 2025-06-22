import 'package:flutter/material.dart';

import 'package:pomodoro/utils/app.dart';
import 'package:pomodoro/utils/notifications/notifications.dart';
import 'package:pomodoro/utils/background_service.dart';

void main() async {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  await NotificationService.initialize(); // Ya no pasa context
  await NotificationService.requestPermissions();

  runApp(MyApp(navigatorKey: navigatorKey));
}
