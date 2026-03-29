import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro/core/data/session_repository.dart';

class MomentumService {
  MomentumService._();
  static final MomentumService instance = MomentumService._();

  static const _streakKey = 'momentum_streak_days';
  static const _lastStreakDateKey = 'momentum_last_streak_date';

  final ValueNotifier<int> streak = ValueNotifier(0);
  final ValueNotifier<int> momentumScore = ValueNotifier(0);

  final _repo = SessionRepository();

  Future<void> init() async {
    await _updateStreak();
    await _updateMomentum();
  }

  Future<void> refresh() async {
    await _updateStreak();
    await _updateMomentum();
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_lastStreakDateKey);
    final currentStreak = prefs.getInt(_streakKey) ?? 0;

    final today = _dateOnly(DateTime.now());
    if (lastDateStr == null) {
      streak.value = 0;
      return;
    }

    final lastDate = DateTime.parse(lastDateStr);
    final diff = today.difference(_dateOnly(lastDate)).inDays;

    if (diff == 0) {
      streak.value = currentStreak;
    } else if (diff == 1) {
      streak.value = currentStreak;
    } else {
      // Streak broken
      await prefs.setInt(_streakKey, 0);
      streak.value = 0;
    }
  }

  Future<void> recordSessionToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_lastStreakDateKey);
    final today = _dateOnly(DateTime.now());
    final todayStr = today.toIso8601String().split('T').first;

    if (lastDateStr == null) {
      await prefs.setString(_lastStreakDateKey, todayStr);
      await prefs.setInt(_streakKey, 1);
      streak.value = 1;
    } else {
      final lastDate = _dateOnly(DateTime.parse(lastDateStr));
      final diff = today.difference(lastDate).inDays;

      if (diff == 0) {
        // Same day, no change to streak count
      } else if (diff == 1) {
        // Consecutive day
        final newStreak = (prefs.getInt(_streakKey) ?? 0) + 1;
        await prefs.setString(_lastStreakDateKey, todayStr);
        await prefs.setInt(_streakKey, newStreak);
        streak.value = newStreak;
      } else {
        // Streak broken, restart from 1
        await prefs.setString(_lastStreakDateKey, todayStr);
        await prefs.setInt(_streakKey, 1);
        streak.value = 1;
      }
    }

    await _updateMomentum();
  }

  Future<void> _updateMomentum() async {
    final goal = await _repo.getDailyGoalMinutes();
    final todaySec = await _repo.todayWorkSeconds();
    final todayMin = todaySec / 60;

    if (goal <= 0) {
      momentumScore.value = todayMin > 0 ? 50 : 0;
      return;
    }

    final score = ((todayMin / goal) * 100).clamp(0, 100).round();
    momentumScore.value = score;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
