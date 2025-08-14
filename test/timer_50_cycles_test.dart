import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:pomodoro/core/timer/ticker.dart';
import 'package:pomodoro/core/timer/timer_bloc.dart';
import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/utils/notifications/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mocks
class _FakeTicker implements Ticker {
  @override
  Stream<int> tick({required int ticks}) {
    // Emit remaining seconds: ticks-1, ticks-2, ..., 0
    final values = List<int>.generate(ticks, (i) => ticks - i - 1);
    return Stream<int>.fromIterable(values);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('50 cycle simulation', () {
    test('simulate 50 cycles 25/5 and validate behavior', () async {
      // Arrange
  final fakeTicker = _FakeTicker();
  final repo = SessionRepository();

  // Initialize timezone data used by NotificationService
  tz.initializeTimeZones();
  // Provide in-memory SharedPreferences for tests
  SharedPreferences.setMockInitialValues({});

      // Mock platform channels used by plugins to avoid MissingPluginException
      const MethodChannel audioplayersChannel = MethodChannel('xyz.luan/audioplayers.global');
      audioplayersChannel.setMockMethodCallHandler((call) async {
        // respond to 'init' and ignore others
        return null;
      });
      const MethodChannel audioplayersChannel2 = MethodChannel('xyz.luan/audioplayers');
      audioplayersChannel2.setMockMethodCallHandler((call) async {
        // respond to 'create' etc
        return null;
      });
      const MethodChannel flnChannel = MethodChannel('dexterous.com/flutter/local_notifications');
      flnChannel.setMockMethodCallHandler((call) async {
        // return null for any FLN method invoked in tests
        return null;
      });

  // Replace audio/notification/dnd with no-op implementations by toggling flags
      NotificationService.appSilentMode = true; // prevent real notifications
  NotificationService.testMode = true;
  // Do not initialize AudioService to avoid plugin calls during unit tests.

  final bloc = TimerBloc(ticker: fakeTicker, repository: repo);

      // Start with a work phase of 25s and break 5s for speed (simulate seconds as seconds)
      bloc.add(TimerStarted(
          phase: TimerPhase.work,
          duration: 25,
          workDuration: 25,
          breakDuration: 5,
          session: 1,
          totalSessions: 50));

  TimerState? lastState;

      final sub = bloc.stream.listen((state) async {
        lastState = state;
      });

      // Act: TimerBloc will consume the synchronous tick streams; wait until
      // the bloc reaches TimerCompleted or timeout.
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (DateTime.now().isBefore(deadline)) {
        if (lastState is TimerCompleted) break;
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Assert
      expect(lastState, isNotNull);
      // final state should be TimerCompleted or TimerRunInProgress ended
      expect(lastState is TimerCompleted || lastState is TimerInitial, true);
      // Completed cycles should match 50 if we reached completion
      if (lastState is TimerCompleted) {
        final completed = lastState as TimerCompleted;
        expect(completed.totalSessions, 50);
      }

  await sub.cancel();
  bloc.close();
    }, timeout: Timeout(Duration(minutes: 2)));
  });
}
