part of 'timer_bloc.dart';

abstract class TimerState extends Equatable {
  final int workDuration; // seconds
  final int breakDuration; // seconds
  const TimerState({required this.workDuration, required this.breakDuration});
}

class TimerInitial extends TimerState {
  const TimerInitial(
      {required super.workDuration, required super.breakDuration});
  @override
  List<Object?> get props => [workDuration, breakDuration];
}

class TimerRunInProgress extends TimerState {
  final TimerPhase phase;
  final int remaining; // seconds
  final int session;
  final int totalSessions;
  final bool paused;
  const TimerRunInProgress({
    required this.phase,
    required this.remaining,
    required this.session,
    required this.totalSessions,
    required super.workDuration,
    required super.breakDuration,
    this.paused = false,
  });
  TimerRunInProgress copyWith({
    TimerPhase? phase,
    int? remaining,
    int? session,
    int? totalSessions,
    bool? paused,
  }) =>
      TimerRunInProgress(
        phase: phase ?? this.phase,
        remaining: remaining ?? this.remaining,
        session: session ?? this.session,
        totalSessions: totalSessions ?? this.totalSessions,
        workDuration: workDuration,
        breakDuration: breakDuration,
        paused: paused ?? this.paused,
      );
  @override
  List<Object?> get props => [
        phase,
        remaining,
        session,
        totalSessions,
        workDuration,
        breakDuration,
        paused
      ];
}

class TimerCompleted extends TimerState {
  final int totalSessions;
  const TimerCompleted({
    required this.totalSessions,
    required super.workDuration,
    required super.breakDuration,
  });
  @override
  List<Object?> get props => [totalSessions, workDuration, breakDuration];
}
