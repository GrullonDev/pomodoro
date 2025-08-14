import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class Dnd {
  static const MethodChannel _channel = MethodChannel('pomodoro/dnd');

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
}
