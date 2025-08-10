import 'dart:async';

// Switched to flutter_bloc import to avoid depending on transitive 'bloc' package directly
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pomodoro/utils/notifications/notifications.dart';
import 'package:pomodoro/core/data/session_repository.dart';
// timezone is configured inside NotificationService when needed

import 'ticker.dart';

part 'timer_event.dart';
part 'timer_state.dart';

enum TimerPhase { work, breakPhase }

/// Estados: work, breakPhase, completed
class TimerBloc extends Bloc<TimerEvent, TimerState> {
  TimerBloc({required Ticker ticker, SessionRepository? repository})
      : _ticker = ticker,
        _repository = repository ?? SessionRepository(),
        super(const TimerInitial(workDuration: 1500, breakDuration: 300)) {
    on<TimerStarted>(_onStarted);
    on<TimerTicked>(_onTicked);
    on<TimerPaused>(_onPaused);
    on<TimerResumed>(_onResumed);
    on<TimerReset>(_onReset);
    on<TimerPhaseCompleted>(_onPhaseCompleted);
  }

  final Ticker _ticker;
  StreamSubscription<int>? _tickerSub;
  final SessionRepository _repository;

  Future<void> _onStarted(TimerStarted event, Emitter<TimerState> emit) async {
    // Programar notificación de finalización
    NotificationService.schedulePhaseEndNotification(
      seconds: event.duration,
      title: 'Fase ${event.phase == TimerPhase.work ? 'Trabajo' : 'Descanso'}',
      body: 'La fase ha terminado, toca para continuar',
    );
    emit(TimerRunInProgress(
      phase: event.phase,
      remaining: event.duration,
      workDuration: event.workDuration,
      breakDuration: event.breakDuration,
      session: event.session,
      totalSessions: event.totalSessions,
    ));
    _tickerSub?.cancel();
    _tickerSub = _ticker.tick(ticks: event.duration).listen((remaining) {
      add(TimerTicked(remaining: remaining));
    });
  }

  void _onTicked(TimerTicked event, Emitter<TimerState> emit) {
    final current = state as TimerRunInProgress;
    if (event.remaining > 0) {
      emit(current.copyWith(remaining: event.remaining));
    } else {
      add(TimerPhaseCompleted());
    }
  }

  void _onPaused(TimerPaused event, Emitter<TimerState> emit) {
    if (state is TimerRunInProgress) {
      _tickerSub?.pause();
      emit((state as TimerRunInProgress).copyWith(paused: true));
    }
  }

  void _onResumed(TimerResumed event, Emitter<TimerState> emit) {
    if (state is TimerRunInProgress) {
      _tickerSub?.resume();
      emit((state as TimerRunInProgress).copyWith(paused: false));
    }
  }

  void _onReset(TimerReset event, Emitter<TimerState> emit) {
    _tickerSub?.cancel();
    emit(TimerInitial(
        workDuration: state.workDuration, breakDuration: state.breakDuration));
  }

  Future<void> _onPhaseCompleted(
      TimerPhaseCompleted event, Emitter<TimerState> emit) async {
    if (state is! TimerRunInProgress) return;
    final current = state as TimerRunInProgress;
    await NotificationService.showTimerFinishedNotification(
      id: 999,
      title: 'Fase completada',
      body: current.phase == TimerPhase.work
          ? 'Buen trabajo! Inicia tu descanso'
          : 'Descanso finalizado. Próxima sesión',
    );
    final completedSession = current.phase == TimerPhase.breakPhase;
    final nextSession =
        completedSession ? current.session + 1 : current.session;
    if (nextSession > current.totalSessions) {
      // Guardar última fase de trabajo si la anterior fue de trabajo y terminó
      if (current.phase == TimerPhase.work) {
        _repository.addSession(PomodoroSession(
            endTime: DateTime.now(), workSeconds: current.workDuration));
      }
      emit(TimerCompleted(
        totalSessions: current.totalSessions,
        workDuration: current.workDuration,
        breakDuration: current.breakDuration,
      ));
      return;
    }
    // Si finalizó fase de trabajo, persistir
    if (current.phase == TimerPhase.work) {
      _repository.addSession(PomodoroSession(
          endTime: DateTime.now(), workSeconds: current.workDuration));
    }
    // Configurable long break logic
    final nextPhase = current.phase == TimerPhase.work
        ? TimerPhase.breakPhase
        : TimerPhase.work;
    int duration = nextPhase == TimerPhase.work
        ? current.workDuration
        : current.breakDuration;
    if (nextPhase == TimerPhase.breakPhase) {
      final interval = await _repository.getLongBreakInterval();
      if (interval > 0 &&
          (nextSession - 1) % interval == 0 &&
          nextSession > 1) {
        final longBreakMin = await _repository.getLongBreakDurationMinutes();
        duration = longBreakMin * 60;
      }
    }
    add(TimerStarted(
      phase: nextPhase,
      duration: duration,
      workDuration: current.workDuration,
      breakDuration: current.breakDuration,
      session: nextSession,
      totalSessions: current.totalSessions,
    ));
    // Check daily goal asynchronously (fire and forget)
    _repository.todayProgress().then((p) {
      if (p >= 1) {
        NotificationService.showSimple(
            title: 'Meta diaria alcanzada',
            body: 'Excelente! Llegaste a tu objetivo de enfoque.');
      }
    });
  }

  @override
  Future<void> close() {
    _tickerSub?.cancel();
    return super.close();
  }
}
