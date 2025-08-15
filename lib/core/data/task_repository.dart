import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TaskItem {
  final String id;
  final String title;
  final bool done;

  TaskItem({required this.id, required this.title, required this.done});

  TaskItem copyWith({String? id, String? title, bool? done}) => TaskItem(
        id: id ?? this.id,
        title: title ?? this.title,
        done: done ?? this.done,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'done': done,
      };

  static TaskItem fromMap(Map<String, dynamic> map) => TaskItem(
        id: map['id'] as String,
        title: map['title'] as String,
        done: map['done'] as bool? ?? false,
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

  Future<TaskItem> add(String title) async {
    final tasks = await load();
    final t = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      done: false,
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

  Future<TaskItem?> nextPending() async {
    final tasks = await load();
    return tasks.firstWhere((e) => !e.done, orElse: () => TaskItem(id: '', title: '', done: true));
  }

  Future<List<TaskItem>> all() => load();
}
