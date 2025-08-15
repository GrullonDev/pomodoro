import 'package:pomodoro/core/domain/entities/task.dart';

abstract class ITaskRepository {
  Future<TaskItem> add(String title, {int work = 25, int brk = 5, int sessions = 4});
  Future<void> markDone(String id);
  Future<void> incrementSession(String id);
  Future<TaskItem?> nextPending();
  Future<List<TaskItem>> all();
}
