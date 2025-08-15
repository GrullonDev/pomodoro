import 'package:pomodoro/core/domain/repositories/task_repository.dart';

class IncrementTaskSessionUseCase {
  final ITaskRepository repo;
  IncrementTaskSessionUseCase(this.repo);
  Future<void> call(String id) => repo.incrementSession(id);
}
