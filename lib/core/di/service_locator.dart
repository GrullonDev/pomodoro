import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/data/task_repository.dart';
import 'package:pomodoro/core/domain/repositories/session_repository.dart';
import 'package:pomodoro/core/domain/repositories/task_repository.dart';
import 'package:pomodoro/core/data/settings_repository.dart';
import 'package:pomodoro/core/domain/repositories/settings_repository.dart';

/// Very lightweight service locator. For larger apps consider get_it.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator I = ServiceLocator._();

  ISessionRepository? _sessionRepo;
  ITaskRepository? _taskRepo;
  ISettingsRepository? _settingsRepo;

  ISessionRepository get sessionRepository =>
      _sessionRepo ??= SessionRepository();
  ITaskRepository get taskRepository => _taskRepo ??= TaskRepository();
  ISettingsRepository get settingsRepository =>
      _settingsRepo ??= SettingsRepository();
}
