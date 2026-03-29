import 'package:flutter/material.dart';

class FocusMode {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Color color;
  final Color accentColor;
  final int workMinutes;
  final int breakMinutes;
  final int sessions;

  const FocusMode({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    required this.accentColor,
    required this.workMinutes,
    required this.breakMinutes,
    required this.sessions,
  });

  static const deepWork = FocusMode(
    id: 'deep_work',
    name: 'Deep Work',
    description: 'Tareas complejas que requieren máxima concentración',
    emoji: '🎯',
    color: Color(0xFF7C6FF7),
    accentColor: Color(0xFF9F96FF),
    workMinutes: 50,
    breakMinutes: 10,
    sessions: 3,
  );

  static const sprint = FocusMode(
    id: 'sprint',
    name: 'Sprint',
    description: 'Clásico Pomodoro, ideal para la mayoría de tareas',
    emoji: '⚡',
    color: Color(0xFFFF6B9D),
    accentColor: Color(0xFFFF8DB5),
    workMinutes: 25,
    breakMinutes: 5,
    sessions: 4,
  );

  static const creative = FocusMode(
    id: 'creative',
    name: 'Creativo',
    description: 'Para diseño, escritura y trabajo creativo',
    emoji: '🎨',
    color: Color(0xFFFFA552),
    accentColor: Color(0xFFFFBD7A),
    workMinutes: 35,
    breakMinutes: 7,
    sessions: 3,
  );

  static const learning = FocusMode(
    id: 'learning',
    name: 'Estudio',
    description: 'Lectura, cursos y aprendizaje profundo',
    emoji: '📚',
    color: Color(0xFF4ECDC4),
    accentColor: Color(0xFF72DBD4),
    workMinutes: 40,
    breakMinutes: 8,
    sessions: 4,
  );

  static const quickWin = FocusMode(
    id: 'quick_win',
    name: 'Quick Win',
    description: 'Tareas rápidas y calentamiento del día',
    emoji: '🏃',
    color: Color(0xFF55EFC4),
    accentColor: Color(0xFF78F3D2),
    workMinutes: 15,
    breakMinutes: 3,
    sessions: 5,
  );

  static List<FocusMode> all() => [deepWork, sprint, creative, learning, quickWin];

  static FocusMode fromId(String id) =>
      all().firstWhere((m) => m.id == id, orElse: () => sprint);
}
