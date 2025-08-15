import 'package:pomodoro/core/domain/entities/task.dart';
import 'package:pomodoro/core/domain/repositories/task_repository.dart';

class NextPendingTaskUseCase {
  final ITaskRepository repo;
  NextPendingTaskUseCase(this.repo);
  Future<TaskItem?> call() => repo.nextPending();
}
