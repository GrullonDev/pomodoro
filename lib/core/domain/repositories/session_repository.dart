import 'package:pomodoro/core/domain/entities/pomodoro_session.dart';

/// Abstraction for session tracking & timer-related settings.
abstract class ISessionRepository {
  Future<void> addSession(PomodoroSession session);
  Future<int> getLongBreakInterval();
  Future<int> getLongBreakDurationMinutes();
  Future<double> todayProgress();
}
