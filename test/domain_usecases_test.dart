import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro/core/data/task_repository.dart';
import 'package:pomodoro/core/domain/usecases/add_task.dart';
import 'package:pomodoro/core/domain/usecases/increment_task_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Provide in-memory shared preferences store for tests
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  test('AddTaskUseCase creates task with provided parameters', () async {
    final repo = TaskRepository();
    final add = AddTaskUseCase(repo);
    final t = await add('Test Task', work: 15, brk: 3, sessions: 2);
    expect(t.title, 'Test Task');
    expect(t.workMinutes, 15);
    expect(t.breakMinutes, 3);
    expect(t.sessions, 2);
  });

  test('IncrementTaskSessionUseCase increments and marks done', () async {
    final repo = TaskRepository();
    final add = AddTaskUseCase(repo);
    final inc = IncrementTaskSessionUseCase(repo);
    final task = await add('Session Task', sessions: 1);
    await inc(task.id);
    final all = await repo.all();
    final updated = all.firstWhere((e) => e.id == task.id);
    expect(updated.sessionsCompleted, 1);
    expect(updated.done, true);
  });
}
