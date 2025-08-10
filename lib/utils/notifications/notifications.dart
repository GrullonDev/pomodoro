import 'package:flutter/foundation.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pomodoro/core/timer/timer_action_bus.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    final pauseResumeAction = DarwinNotificationAction.plain(
      'pause_resume',
      'Pause/Resume',
      options: <DarwinNotificationActionOption>{},
    );
    final skipAction = DarwinNotificationAction.plain(
      'skip',
      'Skip',
      options: <DarwinNotificationActionOption>{},
    );
    final focusCategory = DarwinNotificationCategory(
      'FOCUS_TIMER',
      actions: <DarwinNotificationAction>[pauseResumeAction, skipAction],
      options: <DarwinNotificationCategoryOption>{},
    );

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: <DarwinNotificationCategory>[focusCategory],
    );

    // Initialization settings for both platforms
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings,
        onDidReceiveNotificationResponse:
            (NotificationResponse response) async {
      if (response.actionId == 'pause_resume') {
        TimerActionBus.instance.add('toggle');
      } else if (response.actionId == 'skip') {
        TimerActionBus.instance.add('skip');
      } else {
        final payload = response.payload;
        if (payload != null && payload.startsWith('action:')) {
          final action = payload.substring('action:'.length);
          TimerActionBus.instance.add(action);
        }
      }
    });
  }

  static Future<void> requestPermissions() async {
    // Android: permissions are granted at install time
    // iOS: request permissions explicitly
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static Future<void> showTimerNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pomodoro_timer_channel',
      'Pomodoro Timer',
      channelDescription: 'Timer notifications for Pomodoro app',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      // For Android 13+ notification permission
      enableVibration: true,
      playSound: true,
      // For dynamic island (Android 14+), use styleInformation if needed
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // For iOS 16.1+ Live Activities (Dynamic Island), use plugin like activitykit
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: 'timer',
    );
  }

  static Future<void> showSimple(
      {required String title, required String body, int id = 700}) async {
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_general',
      'General',
      channelDescription: 'Otras notificaciones',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _notificationsPlugin.show(id, title, body,
        const NotificationDetails(android: androidDetails, iOS: ios));
  }

  static Future<void> showTimerFinishedNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Usamos el sonido por defecto del sistema para evitar el crash
    // (PlatformException invalid_sound) mientras no exista el recurso
    // raw "timer_end" (android/app/src/main/res/raw/timer_end.*) y el
    // archivo iOS (ios/Runner/timer_end.aiff). Cuando agregues los
    // archivos, puedes restaurar la propiedad 'sound'.
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_timer_finished_channel',
      'Pomodoro Timer Finished',
      channelDescription: 'Alerta sonora al finalizar el temporizador',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      enableVibration: true,
      playSound: true,
      // sound: RawResourceAndroidNotificationSound('timer_end'), // <-- Re‑habilitar cuando exista el archivo
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true, // Usa sonido por defecto
      // sound: 'timer_end.aiff', // <-- Re‑habilitar cuando agregues el archivo
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'timer_finished',
      );
    } catch (e) {
      debugPrint('Failed to show finished notification: $e');
    }
  }

  static Future<void> schedulePhaseEndNotification({
    required int seconds,
    required String title,
    required String body,
  }) async {
    final scheduled =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_phase_end',
      'Fin de fase',
      channelDescription: 'Notificación al terminar fase',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    try {
      await _notificationsPlugin.zonedSchedule(500, title, body, scheduled,
          const NotificationDetails(android: androidDetails, iOS: ios),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'phase_end',
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
    } catch (e) {
      // Fallback to inexact if exact alarms not permitted
      try {
        await _notificationsPlugin.zonedSchedule(500, title, body, scheduled,
            const NotificationDetails(android: androidDetails, iOS: ios),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'phase_end',
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (e2) {
        debugPrint('Failed to schedule phase end notification: $e / $e2');
      }
    }
  }

  static Future<void> cancelPhaseEndNotification() async {
    await _notificationsPlugin.cancel(500);
  }

  static const int persistentId = 9000;
  static Future<void> showOrUpdatePersistentFocus(
      {required String title,
      required String body,
      required bool paused}) async {
    final androidDetails = AndroidNotificationDetails(
      'pomodoro_focus_persistent',
      'Focus Persistent',
      channelDescription: 'Control del temporizador',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'pause_resume',
          paused ? 'resume' : 'pause',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'skip',
          'skip',
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ],
      // Enable chronometer style countdown by showing elapsed time since base.
      usesChronometer: true,
      chronometerCountDown: true,
    );
    const ios = DarwinNotificationDetails(
        presentAlert: false,
        presentSound: false,
        presentBadge: false,
        categoryIdentifier: 'FOCUS_TIMER');
    await _notificationsPlugin.show(
      persistentId,
      title,
      body, // body holds remaining mm:ss (Android will also show chronometer)
      NotificationDetails(android: androidDetails, iOS: ios),
      payload: 'persistent',
    );
  }

  // Advanced variant: update notification with dynamic remaining time using timestamp base.
  static Future<void> updateChronoRemaining({
    required Duration remaining,
    required bool isWork,
    required bool paused,
    required String phaseTitle,
  }) async {
    final now = DateTime.now();
    // Base time for chronometer countdown: now + remaining (since we count down)
    final endMillis = now.millisecondsSinceEpoch + remaining.inMilliseconds;
    final androidDetails = AndroidNotificationDetails(
      'pomodoro_focus_persistent',
      'Focus Persistent',
      channelDescription: 'Control del temporizador',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      usesChronometer: true,
      chronometerCountDown: true,
      when: endMillis, // Android uses 'when' as base for chronometer
      showWhen: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'pause_resume',
          paused ? 'resume' : 'pause',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        const AndroidNotificationAction(
          'skip',
          'skip',
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ],
    );
    final ios = const DarwinNotificationDetails(
        presentAlert: false,
        presentSound: false,
        presentBadge: false,
        categoryIdentifier: 'FOCUS_TIMER');
    await _notificationsPlugin.show(
      persistentId,
      phaseTitle,
      _formatDuration(remaining),
      NotificationDetails(android: androidDetails, iOS: ios),
      payload: 'persistent',
    );
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '${h.toString().padLeft(2, '0')}:$m:$s' : '$m:$s';
  }

  static Future<void> handleActionFromBackground(String actionId) async {
    // Map platform-specific action id to bus string
    switch (actionId) {
      case 'pause_resume':
        TimerActionBus.instance.add('toggle');
        break;
      case 'skip':
        TimerActionBus.instance.add('skip');
        break;
    }
  }
}
