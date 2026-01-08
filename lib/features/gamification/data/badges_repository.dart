import 'package:flutter/material.dart';
import 'package:pomodoro/features/gamification/domain/game_badge.dart';
import 'package:pomodoro/core/data/session_repository.dart';

class BadgesRepository {
  // Hardcoded list of available badges
  static const List<GameBadge> allBadges = [
    GameBadge(
      id: 'novice_focus',
      title: 'Novato',
      description: 'Completa 25 minutos de enfoque total.',
      icon: Icons.hourglass_bottom,
      type: BadgeType.totalTime,
      requirementThreshold: 25,
    ),
    GameBadge(
      id: 'apprentice_focus',
      title: 'Aprendiz',
      description: 'Acumula 100 minutos de enfoque.',
      icon: Icons.hourglass_top,
      type: BadgeType.totalTime,
      requirementThreshold: 100,
    ),
    GameBadge(
      id: 'expert_focus',
      title: 'Experto',
      description: 'Acumula 500 minutos de enfoque.',
      icon: Icons.psychology,
      type: BadgeType.totalTime,
      requirementThreshold: 500,
    ),
    GameBadge(
      id: 'master_focus',
      title: 'Maestro Zen',
      description: 'Acumula 1000 minutos de enfoque.',
      icon: Icons.self_improvement,
      type: BadgeType.totalTime,
      requirementThreshold: 1000,
    ),
  ];

  final SessionRepository _sessionRepo = SessionRepository();

  /// Returns a map of BadgeID -> Boolean (unlocked or not)
  Future<Map<String, bool>> getBadgesStatus() async {
    final status = <String, bool>{};

    // 1. Check Total Time badges
    // Using XP as proxy for "effort" roughly matches minutes/score
    // Ideally we should have "totalMinutes" tracked separately or access it.
    // Let's use getTodayWorkSeconds for now or implement total career minutes.
    // Wait, SessionRepository stores sessions JSON. We can calculate total career time.
    final sessions = await _sessionRepo.loadSessions();
    final totalMinutes =
        sessions.fold<int>(0, (sum, s) => sum + (s.workSeconds ~/ 60));

    for (final b in allBadges) {
      if (b.type == BadgeType.totalTime) {
        status[b.id] = totalMinutes >= b.requirementThreshold;
      } else {
        // Other types not implemented yet, default locked
        status[b.id] = false;
      }
    }
    return status;
  }
}
