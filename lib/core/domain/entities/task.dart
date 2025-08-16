/// Domain entity for a task decomposed into pomodoro sessions.
class TaskItem {
  final String id;
  final String title;
  final bool done;
  final int workMinutes; // per-session work duration (minutes)
  final int breakMinutes; // per-session break duration (minutes)
  final int sessions; // total sessions required
  final int sessionsCompleted; // sessions finished so far

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
  }) =>
      TaskItem(
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
