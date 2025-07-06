import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';

import 'notifications/notifications.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'pomodoro_service',
      initialNotificationTitle: 'Pomodoro',
      initialNotificationContent: 'Servicio iniciado',
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Pomodoro',
      content: 'El temporizador está activo',
    );
  }

  Timer.periodic(const Duration(minutes: 1), (timer) async {
    await NotificationService.showTimerNotification(
      id: 0,
      title: 'Pomodoro',
      body: 'El temporizador continúa en segundo plano',
    );
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  // If you need to register plugins, uncomment the following line:
  // DartPluginRegistrant.ensureInitialized();
  return true;
}
