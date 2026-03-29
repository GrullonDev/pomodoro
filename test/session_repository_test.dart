import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/domain/entities/pomodoro_session.dart';

import 'helpers/firebase_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    setupAllFirebaseMocks();
    await Firebase.initializeApp();
  });

  group('SessionRepository goalRemainingStream', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('emits updated remaining after adding session', () async {
      final repo = SessionRepository();
      // Set small goal to simplify
      await repo.setDailyGoalMinutes(10); // 10 minutes
      // Start listening BEFORE refreshGoalRemaining() emits so we don't miss
      // the first event on the broadcast stream.
      final firstFuture = repo.goalRemainingStream.first
          .timeout(const Duration(seconds: 2));
      await repo.refreshGoalRemaining();
      final first = await firstFuture;
      // initial remaining should be 10 (or <=10 if prior data)
      expect(first <= 10, true);
      final completer = Completer<int>();
      final sub = repo.goalRemainingStream.skip(1).listen((v) {
        if (!completer.isCompleted) completer.complete(v);
      });
      await repo.addSession(PomodoroSession(
          endTime: DateTime.now(), workSeconds: 60)); // 1 minute
      final updated =
          await completer.future.timeout(const Duration(seconds: 2));
      expect(updated, first - 1 >= 0 ? first - 1 : 0);
      await sub.cancel();
    });
  });
}
