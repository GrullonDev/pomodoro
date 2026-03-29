import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class Dnd {
  static const MethodChannel _channel = MethodChannel('pomodoro/dnd');

  /// Dedicated channel for Apple Watch (WatchConnectivity) communication.
  /// Handled by WatchSessionManager in AppDelegate.swift.
  static const MethodChannel _watchChannel = MethodChannel('pomodoro/watch');

  // Android interruption filter constants (mirror of NotificationManager)
  static const int interruptionFilterNone = 0; // silent
  static const int interruptionFilterAll = 1;
  static const int interruptionFilterPriority = 2;
  static const int interruptionFilterAlarms = 3;

  /// Returns true if notification policy access is granted (Android only).
  static Future<bool> isPolicyGranted() async {
    if (!Platform.isAndroid) return Future.value(false);
    try {
      final granted = await _channel.invokeMethod<bool>('isPolicyGranted');
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Request the policy settings screen (Android only).
  static Future<void> gotoPolicySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('gotoPolicySettings');
    } on PlatformException {
      // ignore
    }
  }

  /// Open the app-specific notification settings screen so the user can
  /// enable notification channels or check DND-related options for this app.
  static Future<void> gotoAppNotificationSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('gotoAppNotificationSettings');
    } on PlatformException {
      // ignore
    }
  }

  /// Get current interruption filter (Android only). Returns int or null.
  static Future<int?> getCurrentFilter() async {
    if (!Platform.isAndroid) return null;
    try {
      final res = await _channel.invokeMethod<int>('getCurrentFilter');
      return res;
    } on PlatformException {
      return null;
    }
  }

  /// Set interruption filter (Android only).
  static Future<void> setInterruptionFilter(int filter) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setInterruptionFilter', {'filter': filter});
    } on PlatformException {
      // ignore
    }
  }

  /// Attempt to start Android lock task (screen pinning / kiosk). Returns true
  /// if the platform acknowledged the request. This is best-effort — full
  /// kiosk mode may require device-owner privileges.
  static Future<bool> startLockTask() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('startLockTask');
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Attempt to stop Android lock task. Returns true if successful.
  static Future<bool> stopLockTask() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('stopLockTask');
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Start a minimal Android foreground service (best-effort).
  /// Pass [remainingSeconds] and [title] so the native service can run its own
  /// countdown when the Dart isolate is suspended in the background.
  static Future<bool> startForegroundService({
    int remainingSeconds = 0,
    bool paused = false,
    String title = 'Pomodoro',
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('startForegroundService', {
        'remainingSeconds': remainingSeconds,
        'paused': paused,
        'title': title,
      });
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Stop the previously started foreground service.
  static Future<bool> stopForegroundService() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('stopForegroundService');
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Update the ongoing foreground notification with a small payload.
  /// This avoids reconstructing complex notification objects on the Dart side
  /// every second and reduces MethodChannel/codec allocations.
  static Future<bool> updateForegroundNotification({
    required int remainingSeconds,
    required bool paused,
    required bool isWork,
    required String title,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final res =
          await _channel.invokeMethod<bool>('updateForegroundNotification', {
        'remainingSeconds': remainingSeconds,
        'paused': paused,
        'isWork': isWork,
        'title': title,
      });
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Extended variant of [updateForegroundNotification] that includes
  /// session / phase context so [WearNotificationHelper] can build a
  /// richer Wear OS notification with session progress and phase label.
  static Future<bool> updateForegroundNotificationWithWear({
    required int remainingSeconds,
    required bool paused,
    required bool isWork,
    required String title,
    required int session,
    required int totalSessions,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final res =
          await _channel.invokeMethod<bool>('updateForegroundNotification', {
        'remainingSeconds': remainingSeconds,
        'paused': paused,
        'isWork': isWork,
        'title': title,
        'session': session,
        'totalSessions': totalSessions,
        'phase': isWork ? 'work' : 'break',
      });
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Sends a haptic / alert event to the ForegroundService which posts a
  /// HIGH-importance notification that buzzes the paired Wear OS watch.
  ///
  /// [event] must be one of: 'work_to_break', 'break_to_work', 'completed'
  static Future<bool> triggerWearHaptic({
    required String event,
    String title = 'Pomodoro',
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('triggerWearHaptic', {
        'event': event,
        'title': title,
      });
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Sends current timer state to a paired Apple Watch via WatchConnectivity.
  /// No-op on Android (Wear OS uses the ForegroundService notification path).
  static Future<void> sendWatchState({
    required int remainingSeconds,
    required bool paused,
    required bool isWork,
    required String title,
    required int session,
    required int totalSessions,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _watchChannel.invokeMethod('syncState', {
        'remaining': remainingSeconds,
        'paused': paused,
        'isWork': isWork,
        'title': title,
        'session': session,
        'totalSessions': totalSessions,
      });
    } on PlatformException {
      // ignore — watch may not be paired
    }
  }

  /// Registers a Dart callback that is invoked when the user taps a
  /// Pause/Resume or Skip button on the watch (Wear OS notification card or
  /// Apple Watch app).
  ///
  /// [handler] receives either 'toggle' (pause/resume) or 'skip'.
  /// The handler routes directly to [TimerActionBus] so the same logic
  /// that handles notification actions also handles watch actions.
  static void setWatchActionHandler(void Function(String action) handler) {
    final channel = Platform.isIOS ? _watchChannel : _channel;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'onWatchAction') {
        final action = (call.arguments as Map?)?.entries
            .firstWhere((e) => e.key == 'action', orElse: () => const MapEntry('action', null))
            .value as String?;
        if (action != null) handler(action);
      }
    });
  }
}
