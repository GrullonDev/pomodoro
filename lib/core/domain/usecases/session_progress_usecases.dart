import 'package:pomodoro/core/domain/entities/pomodoro_session.dart';
import 'package:pomodoro/core/domain/repositories/session_repository.dart';

class AddSessionUseCase {
  final ISessionRepository repo;
  AddSessionUseCase(this.repo);
  Future<void> call(PomodoroSession s) => repo.addSession(s);
}

class GetLongBreakIntervalUseCase {
  final ISessionRepository repo;
  GetLongBreakIntervalUseCase(this.repo);
  Future<int> call() => repo.getLongBreakInterval();
}

class GetLongBreakDurationMinutesUseCase {
  final ISessionRepository repo;
  GetLongBreakDurationMinutesUseCase(this.repo);
  Future<int> call() => repo.getLongBreakDurationMinutes();
}

class GetTodayProgressUseCase {
  final ISessionRepository repo;
  GetTodayProgressUseCase(this.repo);
  Future<double> call() => repo.todayProgress();
}
