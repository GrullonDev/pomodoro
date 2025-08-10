part of 'timer_bloc.dart';

abstract class TimerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TimerStarted extends TimerEvent {
  final TimerPhase phase;
  final int duration; // seconds
  final int workDuration;
  final int breakDuration;
  final int session;
  final int totalSessions;
  TimerStarted({
    required this.phase,
    required this.duration,
    required this.workDuration,
    required this.breakDuration,
    required this.session,
    required this.totalSessions,
  });
  @override
  List<Object?> get props =>
      [phase, duration, workDuration, breakDuration, session, totalSessions];
}

class TimerTicked extends TimerEvent {
  final int remaining;
  TimerTicked({required this.remaining});
  @override
  List<Object?> get props => [remaining];
}

class TimerPaused extends TimerEvent {}

class TimerResumed extends TimerEvent {}

class TimerReset extends TimerEvent {}

class TimerPhaseCompleted extends TimerEvent {}
