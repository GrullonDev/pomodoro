import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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
  DartPluginRegistrant.ensureInitialized();

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
  DartPluginRegistrant.ensureInitialized();
  return true;
}
