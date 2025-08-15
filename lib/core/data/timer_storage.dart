import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedTimerState {
  final String phase; // 'work' or 'break'
  final int remaining; // seconds
  final int workDuration;
  final int breakDuration;
  final bool paused;
  final int session;
  final int totalSessions;
  final int timestamp; // epoch millis when saved

  SavedTimerState({
    required this.phase,
    required this.remaining,
    required this.workDuration,
    required this.breakDuration,
    required this.paused,
    required this.session,
    required this.totalSessions,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'phase': phase,
        'remaining': remaining,
        'workDuration': workDuration,
        'breakDuration': breakDuration,
        'paused': paused,
        'session': session,
        'totalSessions': totalSessions,
        'timestamp': timestamp,
      };

  factory SavedTimerState.fromMap(Map<String, dynamic> m) => SavedTimerState(
        phase: m['phase'] as String,
        remaining: m['remaining'] as int,
        workDuration: m['workDuration'] as int,
        breakDuration: m['breakDuration'] as int,
        paused: m['paused'] as bool,
        session: m['session'] as int,
        totalSessions: m['totalSessions'] as int,
        timestamp: m['timestamp'] as int,
      );
}

class TimerStorage {
  static const _key = 'timer_saved_state_v1';

  static Future<void> save(SavedTimerState s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(s.toMap()));
  }

  static Future<SavedTimerState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return SavedTimerState.fromMap(m);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
