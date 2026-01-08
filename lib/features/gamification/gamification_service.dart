import 'package:flutter/foundation.dart';
import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/features/gamification/domain/level_calculator.dart';

class GamificationService {
  GamificationService._();
  static final GamificationService instance = GamificationService._();

  final SessionRepository _repo = SessionRepository();

  // Observable state
  final ValueNotifier<int> currentXp = ValueNotifier(0);
  final ValueNotifier<int> currentLevel = ValueNotifier(1);
  final ValueNotifier<double> levelProgress = ValueNotifier(0.0);

  Future<void> init() async {
    // Load XP from persistent storage (we might need to add this to SessionRepository or a new Repo)
    // For now, let's assume we store 'totalXP' in SharedPreferences via SessionRepository extension or direct.
    // Since SessionRepository is the specialized data layer, let's simulate it or add it.
    // For MVP, I'll rely on a simple int in user preferences.
    final xp = await _repo.getTotalXP();
    currentXp.value = xp;
    _updateDerived(xp);
  }

  void _updateDerived(int xp) {
    currentLevel.value = LevelCalculator.getLevel(xp);
    levelProgress.value = LevelCalculator.progressToNextLevel(xp);
  }

  Future<void> awardXP(int amount) async {
    final oldXp = currentXp.value;
    final newXp = oldXp + amount;

    await _repo.setTotalXP(newXp);

    currentXp.value = newXp;
    _updateDerived(newXp);

    // Check for level up event if needed to trigger UI effects
    final oldLevel = LevelCalculator.getLevel(oldXp);
    final newLevel = LevelCalculator.getLevel(newXp);
    if (newLevel > oldLevel) {
      // Level Up!
      // notification or callback system could go here
    }
  }
}
