/// Domain entity representing a single focused pomodoro work session.
class PomodoroSession {
  final DateTime endTime; // moment the work phase ended
  final int workSeconds; // effective focused seconds

  PomodoroSession({required this.endTime, required this.workSeconds});

  Map<String, dynamic> toMap() => {
        'endTime': endTime.toIso8601String(),
        'workSeconds': workSeconds,
      };

  factory PomodoroSession.fromMap(Map<String, dynamic> map) => PomodoroSession(
        endTime: DateTime.parse(map['endTime'] as String),
        workSeconds: map['workSeconds'] as int,
      );
}
