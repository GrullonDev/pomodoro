import 'package:flutter/material.dart';

enum BadgeType {
  streak,
  totalTime,
  earlyBird,
  nightOwl,
}

class GameBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final BadgeType type;
  final int
      requirementThreshold; // Generic integer threshold (minutes, days, etc.)

  const GameBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.requirementThreshold,
  });
}
