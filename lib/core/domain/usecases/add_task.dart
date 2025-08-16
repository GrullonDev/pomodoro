import 'package:pomodoro/core/domain/entities/task.dart';
import 'package:pomodoro/core/domain/repositories/task_repository.dart';

class AddTaskUseCase {
  final ITaskRepository repo;
  AddTaskUseCase(this.repo);
  Future<TaskItem> call(String title,
          {int work = 25, int brk = 5, int sessions = 4}) =>
      repo.add(title, work: work, brk: brk, sessions: sessions);
}
