import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TaskItem {
  final String id;
  final String title;
  final bool done;
  final int workMinutes; // duración work por sesión
  final int breakMinutes; // duración break por sesión
  final int sessions; // sesiones para completarla
  final int sessionsCompleted; // sesiones completadas hasta ahora

  TaskItem({
    required this.id,
    required this.title,
    required this.done,
    required this.workMinutes,
    required this.breakMinutes,
    required this.sessions,
    required this.sessionsCompleted,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    bool? done,
    int? workMinutes,
    int? breakMinutes,
    int? sessions,
    int? sessionsCompleted,
  }) => TaskItem(
        id: id ?? this.id,
        title: title ?? this.title,
        done: done ?? this.done,
        workMinutes: workMinutes ?? this.workMinutes,
        breakMinutes: breakMinutes ?? this.breakMinutes,
        sessions: sessions ?? this.sessions,
        sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'done': done,
        'workMinutes': workMinutes,
        'breakMinutes': breakMinutes,
        'sessions': sessions,
        'sessionsCompleted': sessionsCompleted,
      };

  static TaskItem fromMap(Map<String, dynamic> map) => TaskItem(
        id: map['id'] as String,
        title: map['title'] as String,
        done: map['done'] as bool? ?? false,
        workMinutes: map['workMinutes'] as int? ?? 25,
        breakMinutes: map['breakMinutes'] as int? ?? 5,
        sessions: map['sessions'] as int? ?? 4,
        sessionsCompleted: map['sessionsCompleted'] as int? ?? 0,
      );
}

class TaskRepository {
  static const _key = 'tasks_v1';

  Future<List<TaskItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(TaskItem.fromMap)
        .toList(growable: true);
  }

  Future<void> _save(List<TaskItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(tasks.map((e) => e.toMap()).toList());
    await prefs.setString(_key, jsonStr);
  }

  Future<TaskItem> add(String title,{int work=25,int brk=5,int sessions=4}) async {
    final tasks = await load();
    final t = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      done: false,
      workMinutes: work,
      breakMinutes: brk,
      sessions: sessions,
      sessionsCompleted: 0,
    );
    tasks.add(t);
    await _save(tasks);
    return t;
  }

  Future<void> markDone(String id) async {
    final tasks = await load();
    final idx = tasks.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    tasks[idx] = tasks[idx].copyWith(done: true);
    await _save(tasks);
  }

  Future<void> incrementSession(String id) async {
    final tasks = await load();
    final idx = tasks.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    var task = tasks[idx];
    final newCompleted = (task.sessionsCompleted + 1).clamp(0, task.sessions);
    final done = newCompleted >= task.sessions;
    task = task.copyWith(sessionsCompleted: newCompleted, done: done);
    tasks[idx] = task;
    await _save(tasks);
  }

  Future<TaskItem?> nextPending() async {
    final tasks = await load();
    try {
      return tasks.firstWhere((e) => !e.done);
    } catch (_) {
      return null;
    }
  }

  Future<List<TaskItem>> all() => load();
}
