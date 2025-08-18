import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro/core/domain/entities/pomodoro_session.dart';
import 'package:pomodoro/core/domain/repositories/session_repository.dart';
import 'package:pomodoro/core/auth/auth_service.dart';
// Firebase usage temporarily disabled. To re-enable, restore these imports
// and ensure firebase_core is initialized in `main.dart`.
// TODO: To re-enable Firestore/auth sync:
// 1) Uncomment the imports for `cloud_firestore` and `firebase_auth`.
// 2) Restore calls to `FirebaseAuth.instance.currentUser?.uid` and the Firestore upload.
// 3) Consider making Firestore sync a best-effort background job with retries.
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

class SessionRepository implements ISessionRepository {
  static const _key = 'sessions_json'; // legacy (guest / pre-auth)
  // Per-user key prefix when storing locally; final key: sessions_json_<uid>
  static String _userKey(String? uid) => uid == null ? _key : '${_key}_$uid';
  static const _goalKey = 'daily_goal_minutes';
  static const _longBreakIntervalKey = 'long_break_interval';
  static const _longBreakDurationKey = 'long_break_duration_minutes';
  static const _persistentNotifKey = 'persistent_notification_enabled';
  static const _last5AlertKey = 'last5_alert_enabled';
  static const _last5SoundKey = 'last5_sound_enabled';
  static const _last5FlashKey = 'last5_flash_enabled';
  static const _tickingSoundKey = 'ticking_sound_enabled';
  static const _tickingVolumeKey = 'ticking_sound_volume';
  static const _vibrationEnabledKey = 'vibration_enabled';
  static const _hapticEnabledKey = 'haptic_enabled';
  static const _alarmSoundKey = 'alarm_sound';
  static const _alarmDurationKey = 'alarm_duration_seconds';
  // Theme & preset keys moved to SettingsRepository
  static const _widgetEnabledKey = 'home_widget_enabled';
  static const _notificationActionsKey = 'notification_actions_enabled';
  static const _keyboardShortcutsKey = 'keyboard_shortcuts_enabled';
  static const _wearableSupportKey = 'wearable_support_enabled';
  static const _onboardingSeenKey = 'onboarding_seen';
  // Stream for live daily goal remaining updates
  static final SessionRepository _singleton = SessionRepository._internal();
  factory SessionRepository() => _singleton;
  SessionRepository._internal();

  final StreamController<int> _goalRemainingController =
      StreamController<int>.broadcast();
  Stream<int> get goalRemainingStream => _goalRemainingController.stream;
  bool _goalRefreshing = false;

  Future<void> refreshGoalRemaining() async {
    if (_goalRefreshing) return; // simple reentrancy guard
    _goalRefreshing = true;
    try {
      final goal = await getDailyGoalMinutes();
      final todaySec = await todayWorkSeconds();
      final remainingMin = goal - (todaySec / 60).floor();
      _goalRemainingController.add(remainingMin.clamp(0, goal));
    } finally {
      _goalRefreshing = false;
    }
  }

  Future<List<PomodoroSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
  // Determine UID (Firebase or local fallback)
  final uid = await AuthService.instance.currentUid();
    final raw = prefs.getString(_userKey(uid));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => PomodoroSession.fromMap(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  @override
  Future<void> addSession(PomodoroSession session) async {
    final prefs = await SharedPreferences.getInstance();
  final uid = await AuthService.instance.currentUid();
    final current = await loadSessions();
    current.add(session);
    await prefs.setString(
        _userKey(uid), jsonEncode(current.map((e) => e.toMap()).toList()));
    // Firestore sync (best effort)
    // Firestore sync disabled while Firebase is not configured.
    // TODO: restore Firestore best-effort sync here using `FirebaseFirestore.instance`
    scheduleMicrotask(() => refreshGoalRemaining());
  }

  Future<Map<String, int>> workSecondsByDayLast7() async {
    final sessions = await loadSessions();
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    final map = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      final key = _formatDay(d);
      map[key] = 0;
    }
    for (final s in sessions) {
      if (s.endTime.isAfter(start.subtract(const Duration(seconds: 1)))) {
        final key = _formatDay(s.endTime);
        if (map.containsKey(key)) {
          map[key] = map[key]! + s.workSeconds;
        }
      }
    }
    return map;
  }

  Future<void> setDailyGoalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, minutes);
  }

  Future<int> getDailyGoalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_goalKey) ?? 120; // default 2h
  }

  Future<void> setLongBreakInterval(int interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_longBreakIntervalKey, interval);
  }

  @override
  @override
  Future<int> getLongBreakInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_longBreakIntervalKey) ?? 4; // default every 4
  }

  Future<void> setLongBreakDurationMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_longBreakDurationKey, minutes);
  }

  @override
  @override
  Future<int> getLongBreakDurationMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_longBreakDurationKey) ?? 10; // default 10 min
  }

  Future<void> setPersistentNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_persistentNotifKey, enabled);
  }

  Future<bool> isPersistentNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_persistentNotifKey) ?? true; // default enabled
  }

  Future<void> setLast5AlertEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_last5AlertKey, enabled);
  }

  Future<bool> isLast5AlertEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_last5AlertKey) ?? false; // default disabled
  }

  Future<void> setLast5SoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_last5SoundKey, enabled);
  }

  Future<bool> isLast5SoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_last5SoundKey) ?? true; // default enabled
  }

  Future<void> setLast5FlashEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_last5FlashKey, enabled);
  }

  Future<bool> isLast5FlashEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_last5FlashKey) ?? true; // default enabled
  }

  Future<void> setTickingSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tickingSoundKey, enabled);
  }

  Future<bool> isTickingSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tickingSoundKey) ?? true; // default enabled
  }

  Future<void> setTickingVolume(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_tickingVolumeKey, v.clamp(0.0, 1.0));
  }

  Future<double> getTickingVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_tickingVolumeKey) ?? 0.5; // default 50%
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }

  Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  Future<void> setHapticEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticEnabledKey, enabled);
  }

  Future<bool> isHapticEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hapticEnabledKey) ?? true;
  }

  Future<void> setAlarmSound(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alarmSoundKey, name);
  }

  Future<String> getAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_alarmSoundKey) ?? 'default';
  }

  Future<void> setAlarmDurationSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_alarmDurationKey, seconds);
  }

  Future<int> getAlarmDurationSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_alarmDurationKey) ?? 5; // default 5s
  }

  // Removed theme & preset methods (handled by SettingsRepository now)

  Future<void> setHomeWidgetEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_widgetEnabledKey, enabled);
  }

  Future<bool> isHomeWidgetEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_widgetEnabledKey) ?? true;
  }

  Future<void> setNotificationActionsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationActionsKey, enabled);
  }

  Future<bool> isNotificationActionsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationActionsKey) ?? true;
  }

  Future<void> setKeyboardShortcutsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyboardShortcutsKey, enabled);
  }

  Future<bool> isKeyboardShortcutsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyboardShortcutsKey) ?? false;
  }

  Future<void> setWearableSupportEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wearableSupportKey, enabled);
  }

  Future<bool> isWearableSupportEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wearableSupportKey) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  Future<bool> isOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  @override
  @override
  Future<double> todayProgress() async {
    final goal = await getDailyGoalMinutes();
    final todaySec = await todayWorkSeconds();
    if (goal <= 0) return 0;
    return (todaySec / 60) / goal;
  }

  // MIGRATION from legacy 'time' string storage
  Future<void> migrateLegacyIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    // Only migrate into guest key if user has no per-user data
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      return; // already migrated (guest)
    }
    final legacy = prefs.getString('time');
    if (legacy == null || legacy.isEmpty) return;
    final split = legacy.split('/');
    final List<PomodoroSession> sessions = [];
    for (final s in split) {
      final parts = s.trim().split(' ');
      if (parts.length >= 2) {
        final minutes = int.tryParse(parts[1]);
        if (minutes != null) {
          DateTime date;
          if (parts.length >= 3) {
            // expecting dd-mm-yyyy
            final dmy = parts[2].split('-');
            if (dmy.length == 3) {
              final d = int.tryParse(dmy[0]) ?? 1;
              final m = int.tryParse(dmy[1]) ?? 1;
              final y = int.tryParse(dmy[2]) ?? DateTime.now().year;
              date = DateTime(y, m, d, 23, 59, 0);
            } else {
              date = DateTime.now();
            }
          } else {
            date = DateTime.now();
          }
          sessions
              .add(PomodoroSession(endTime: date, workSeconds: minutes * 60));
        }
      }
    }
    if (sessions.isNotEmpty) {
      await prefs.setString(
          _key, jsonEncode(sessions.map((e) => e.toMap()).toList()));
    }
  }

  Future<int> todayWorkSeconds() async {
    final sessions = await loadSessions();
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return sessions
        .where((s) => s.endTime.isAfter(start))
        .fold<int>(0, (a, b) => a + b.workSeconds);
  }

  void dispose() {
    _goalRemainingController.close();
  }

  String _formatDay(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
