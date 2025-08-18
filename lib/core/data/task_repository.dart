import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro/core/domain/entities/task.dart';
import 'package:pomodoro/core/domain/repositories/task_repository.dart';

class TaskRepository implements ITaskRepository {
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

  @override
  Future<TaskItem> add(String title,
      {int work = 25, int brk = 5, int sessions = 4}) async {
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

  @override
  Future<void> markDone(String id) async {
    final tasks = await load();
    final idx = tasks.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    tasks[idx] = tasks[idx].copyWith(done: true);
    await _save(tasks);
  }

  @override
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

  @override
  Future<TaskItem?> nextPending() async {
    final tasks = await load();
    try {
      return tasks.firstWhere((e) => !e.done);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TaskItem>> all() => load();
}
