import 'dart:async';

// Switched to flutter_bloc import to avoid depending on transitive 'bloc' package directly
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pomodoro/utils/notifications/notifications.dart';
import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/domain/repositories/session_repository.dart';
import 'package:pomodoro/core/domain/entities/pomodoro_session.dart';
// timezone is configured inside NotificationService when needed

import 'ticker.dart';
import 'package:pomodoro/core/data/timer_storage.dart';

part 'timer_event.dart';
part 'timer_state.dart';

// Task automation support
typedef TaskCycleCompletedCallback = Future<void> Function();

enum TimerPhase { work, breakPhase }

/// Estados: work, breakPhase, completed
class TimerBloc extends Bloc<TimerEvent, TimerState> {
  final TaskCycleCompletedCallback? onTaskCycleCompleted;
  TimerBloc(
      {required Ticker ticker,
      ISessionRepository? repository,
      this.onTaskCycleCompleted})
      : _ticker = ticker,
        _repository = repository ?? SessionRepository(),
        super(const TimerInitial(workDuration: 1500, breakDuration: 300)) {
    on<TimerStarted>(_onStarted);
    on<TimerTicked>(_onTicked);
    on<TimerPaused>(_onPaused);
    on<TimerResumed>(_onResumed);
    on<TimerReset>(_onReset);
    on<TimerPhaseCompleted>(_onPhaseCompleted);
    // Try to restore saved timer state if present
    _tryRestoreSavedState();
  }

  void _tryRestoreSavedState() async {
    final saved = await TimerStorage.load();
    if (saved == null) return;
    // Only restore if saved within a reasonable window (e.g., 24 hours)
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - saved.timestamp > Duration(hours: 24).inMilliseconds) return;
    final phase =
        saved.phase == 'work' ? TimerPhase.work : TimerPhase.breakPhase;
    // Dispatch start with saved remaining and paused state
    add(TimerStarted(
      phase: phase,
      duration: saved.remaining,
      workDuration: saved.workDuration,
      breakDuration: saved.breakDuration,
      session: saved.session,
      totalSessions: saved.totalSessions,
    ));
    if (saved.paused) add(TimerPaused());
  }

  final Ticker _ticker;
  StreamSubscription<int>? _tickerSub;
  int? _lastSavedTimestamp;
  final ISessionRepository _repository;

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
    // Persist initial state
    await TimerStorage.save(SavedTimerState(
      phase: event.phase == TimerPhase.work ? 'work' : 'break',
      remaining: event.duration,
      workDuration: event.workDuration,
      breakDuration: event.breakDuration,
      paused: false,
      session: event.session,
      totalSessions: event.totalSessions,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  void _onTicked(TimerTicked event, Emitter<TimerState> emit) {
    final current = state as TimerRunInProgress;
    if (event.remaining > 0) {
      emit(current.copyWith(remaining: event.remaining));
      // Throttle persistent saves to every ~5 seconds to avoid IO churn
      final lastSaved = _lastSavedTimestamp ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastSaved > 5000) {
        _lastSavedTimestamp = now;
        TimerStorage.save(SavedTimerState(
          phase: current.phase == TimerPhase.work ? 'work' : 'break',
          remaining: event.remaining,
          workDuration: current.workDuration,
          breakDuration: current.breakDuration,
          paused: current.paused,
          session: current.session,
          totalSessions: current.totalSessions,
          timestamp: now,
        ));
      }
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

  Future<void> _onReset(TimerReset event, Emitter<TimerState> emit) async {
    _tickerSub?.cancel();
    await TimerStorage.clear();
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
    // Calcular el tiempo efectivo de trabajo de la fase que termina (solo si era trabajo)
    // Si el usuario saltó antes de terminar, remaining > 0 y se descuenta.
    // Clamp para evitar valores fuera de rango.
    int effectiveWorkSeconds() {
      if (current.phase != TimerPhase.work) return 0;
      final elapsed = current.workDuration - current.remaining;
      if (elapsed <= 0) return 0; // muy corto / no iniciado
      if (elapsed > current.workDuration) return current.workDuration;
      return elapsed;
    }

    if (nextSession > current.totalSessions) {
      // Guardar última fase de trabajo si la anterior fue de trabajo y terminó
      if (current.phase == TimerPhase.work) {
        final eff = effectiveWorkSeconds();
        if (eff > 0) {
          _repository.addSession(
              PomodoroSession(endTime: DateTime.now(), workSeconds: eff));
        }
      }
      // Completed overall flow - clear any persisted timer state
      await TimerStorage.clear();
      emit(TimerCompleted(
        totalSessions: current.totalSessions,
        workDuration: current.workDuration,
        breakDuration: current.breakDuration,
      ));
      // Notificar que terminó un ciclo completo (trabajo+descansos de las sesiones)
      if (onTaskCycleCompleted != null) {
        await onTaskCycleCompleted!();
      }
      return;
    }
    // Si finalizó fase de trabajo, persistir
    if (current.phase == TimerPhase.work) {
      final eff = effectiveWorkSeconds();
      if (eff > 0) {
        _repository.addSession(
            PomodoroSession(endTime: DateTime.now(), workSeconds: eff));
      }
    }
    // Increment per-task session after completing a break (i.e., a full cycle)
    if (completedSession && onTaskCycleCompleted != null) {
      // callback will mark task sessions externally when full cycle ends; for partial we could add another callback if needed
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
