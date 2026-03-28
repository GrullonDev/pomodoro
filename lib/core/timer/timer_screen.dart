import 'dart:async';
import 'dart:io';
import 'dart:math';

// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/data/task_repository.dart';
import 'package:pomodoro/core/domain/entities/task.dart';
import 'package:pomodoro/core/timer/ticker.dart';
import 'package:pomodoro/core/timer/timer_action_bus.dart';
import 'package:pomodoro/core/timer/timer_bloc.dart';
import 'package:pomodoro/features/breaks/break_activity.dart';
import 'package:pomodoro/features/focus_modes/focus_mode.dart';
import 'package:pomodoro/features/momentum/momentum_service.dart';
import 'package:pomodoro/features/summary/session_summary_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
// audio handled by AudioService singleton
import 'package:pomodoro/utils/audio_service.dart';
import 'package:pomodoro/utils/dnd.dart';
import 'package:pomodoro/utils/notifications/notifications.dart';
import 'package:pomodoro/utils/app.dart';
import 'package:pomodoro/features/gamification/gamification_service.dart';
import 'package:pomodoro/features/integrations/calendar/calendar_service.dart';

class TimerScreen extends StatelessWidget {
  final int workMinutes;
  final int breakMinutes;
  final int sessions;
  final TaskItem? task;
  final FocusMode? focusMode;

  const TimerScreen({
    super.key,
    required this.workMinutes,
    required this.breakMinutes,
    required this.sessions,
    this.task,
    this.focusMode,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMode = focusMode ?? FocusMode.sprint;
    final workSeconds = workMinutes * 60;
    final breakSeconds = breakMinutes * 60;

    return BlocProvider(
      create: (_) => TimerBloc(
        ticker: const Ticker(),
        repository: SessionRepository(),
        onTaskCycleCompleted: task == null
            ? null
            : () async {
                final repo = TaskRepository();
                if (task!.id.isNotEmpty) {
                  await repo.markDone(task!.id);
                }
              },
      )..add(TimerStarted(
          phase: TimerPhase.work,
          duration: workSeconds,
          workDuration: workSeconds,
          breakDuration: breakSeconds,
          session: 1,
          totalSessions: task?.sessions ?? sessions,
        )),
      child: _TimerView(
        focusMode: effectiveMode,
        taskTitle: task?.title,
      ),
    );
  }
}

/// Inicia una serie de tareas secuenciales.
class TaskFlowStarter {
  static Future<void> startFlow(BuildContext context,
      {required List<TaskItem> tasks,
      required int defaultWork,
      required int defaultBreak,
      required int defaultSessions}) async {
    // Buscar primera pendiente
    TaskItem? next;
    try {
      next = tasks.firstWhere((t) => !t.done);
    } catch (_) {
      next = null;
    }
    if (next == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          workMinutes: defaultWork,
          breakMinutes: defaultBreak,
          sessions: defaultSessions,
          task: next,
        ),
      ),
    );
    // Al regresar, preguntar por la siguiente si existe
    final repo = TaskRepository();
    final all = await repo.all();
    final pending = all.where((e) => !e.done).toList();
    if (pending.isEmpty) return; // flujo terminado
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Continuar con la siguiente tarea?'),
        content: Text(pending.first.title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí')),
        ],
      ),
    );
    if (proceed == true) {
      await startFlow(context,
          tasks: all,
          defaultWork: defaultWork,
          defaultBreak: defaultBreak,
          defaultSessions: defaultSessions);
    }
  }
}

class _TimerView extends StatefulWidget {
  final FocusMode focusMode;
  final String? taskTitle;

  const _TimerView({required this.focusMode, this.taskTitle});

  @override
  State<_TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<_TimerView>
    with SingleTickerProviderStateMixin {
  int? _previousDndFilter;
  bool _dndPromptShown = false;
  late final StreamSubscription<String> _actionSub;
  int _lastNotifSecond = -1; // throttling control
  int _lastHapticToggleStamp = 0;
  bool _last5AlertPlayed = false;
  int _todayGoalRemaining = -1; // minutes remaining
  int _dailyGoalMinutes = 0;
  final _repo = SessionRepository();
  AnimationController? _pulseController; // nullable for hot reload safety
  // Audio playback delegated to a singleton service to avoid repeated
  // create/dispose churn which on some Android devices led to MediaPlayer
  // errors and OOM.
  bool _flashing = false;
  Timer? _flashTimer;
  bool _flashEnabled = true;
  bool _soundEnabled = true;
  bool _tickingEnabled = true;
  // audio state moved to AudioService

  String _format(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _initPulse();
    // Preload sound assets via AudioService (best-effort)
    AudioService.instance.preload();
    // Solicitar permisos DND en Android (best-effort). If not granted, show a
    // friendly dialog offering to open settings or use an app-local silent mode.
    if (Platform.isAndroid) {
      Dnd.isPolicyGranted().then((granted) {
        if (!granted && mounted && !_dndPromptShown) {
          _dndPromptShown = true;
          // Show after first frame so context is valid
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (ctx) => AlertDialog(
                title: const Text('Permiso de No Interrumpir'),
                content: const Text(
                    'Para silenciar todo el teléfono durante tus sesiones de trabajo, concede acceso al Modo No Interrumpir. Si prefieres no concederlo, puedes silenciar solo las notificaciones de la app.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Use app-level silent mode as fallback
                      // Import NotificationService and set flag
                      NotificationService.appSilentMode = true;
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Modo silencioso de la app activado')),
                      );
                    },
                    child: const Text('Usar modo silencioso de la app'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Recordar después'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      // Abrir ajustes de permiso DND
                      Dnd.gotoPolicySettings();
                    },
                    child: const Text('Abrir ajustes'),
                  ),
                ],
              ),
            );
          });
        }
      });
    }
    _repo.goalRemainingStream.listen((val) {
      if (mounted) setState(() => _todayGoalRemaining = val);
    });
    // Load user preference toggles
    _repo.isLast5FlashEnabled().then((v) {
      if (mounted) setState(() => _flashEnabled = v);
    });
    _repo.isLast5SoundEnabled().then((v) {
      if (mounted) setState(() => _soundEnabled = v);
    });
    _repo.isTickingSoundEnabled().then((v) {
      if (mounted) setState(() => _tickingEnabled = v);
    });
    // Preload audio via centralized service (fire & forget)
    AudioService.instance.preload();
    _repo.refreshGoalRemaining();
    _actionSub = TimerActionBus.instance.stream.listen((action) {
      final bloc = context.read<TimerBloc>();
      final st = bloc.state;
      if (st is TimerRunInProgress) {
        if (action == 'toggle') {
          bloc.add(st.paused ? TimerResumed() : TimerPaused());
        } else if (action == 'skip') {
          bloc.add(TimerPhaseCompleted());
        }
      }
    });
    _loadGoalRemaining();
  }

  @override
  void dispose() {
    // Ensure we restore DND if the view is disposed while we changed it
    if (Platform.isAndroid && _previousDndFilter != null) {
      Dnd.setInterruptionFilter(_previousDndFilter!);
      _previousDndFilter = null;
    }
    _actionSub.cancel();
    _pulseController?.dispose();
    _flashTimer?.cancel();
    // Centralized players live in AudioService; do not dispose here.
    super.dispose();
  }

  void _initPulse() {
    // Avoid re-creating on hot reload if already exists
    _pulseController ??=
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);
  }

  Future<void> _loadGoalRemaining() async {
    final goal = await _repo.getDailyGoalMinutes();
    final todaySec = await _repo.todayWorkSeconds();
    final remainingMin = goal - (todaySec / 60).floor();
    if (mounted) {
      setState(() {
        _dailyGoalMinutes = goal;
        _todayGoalRemaining = remainingMin.clamp(0, goal);
      });
    }
  }

  Future<void> _playLast5Sound() async {
    if (!_soundEnabled) return;
    try {
      await AudioService.instance.playLast5();
    } catch (e) {
      debugPrint('Play sound failed: $e');
    }
  }

  // beep generation moved to AudioService

  void _startFlash() {
    _flashTimer?.cancel();
    if (!_flashEnabled) return;
    setState(() => _flashing = true);
    _flashTimer = Timer.periodic(const Duration(milliseconds: 180), (t) {
      if (!mounted) return;
      setState(() => _flashing = !_flashing);
    });
  }

  void _stopFlash() {
    _flashTimer?.cancel();
    if (mounted) setState(() => _flashing = false);
  }

  @override
  Widget build(BuildContext context) {
    final phaseColor = widget.focusMode.color;
    final flashOverlay = _flashing
        ? IgnorePointer(
            child: Container(
            color: phaseColor.withValues(alpha: 0.12),
          ))
        : const SizedBox.shrink();

    return AnimatedGradientShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.focusMode.name,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)),
              onPressed: () => context.read<TimerBloc>().add(TimerReset()),
              tooltip: 'Reiniciar',
            )
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: BlocConsumer<TimerBloc, TimerState>(
                listener: (context, state) {
                  if (!mounted) return;
                  final loc = AppLocalizations.of(context);
                  // Activar DND al iniciar trabajo: capture previous filter once
                  if (state is TimerRunInProgress &&
                      state.phase == TimerPhase.work &&
                      !state.paused) {
                    if (Platform.isAndroid) {
                      // Only capture previous filter the first time we activate DND
                      if (_previousDndFilter == null) {
                        Dnd.getCurrentFilter().then((filter) async {
                          _previousDndFilter = filter;
                          final granted = await Dnd.isPolicyGranted();
                          if (!granted) {
                            // Can't change system DND without user permission: fallback
                            NotificationService.appSilentMode = true;
                            debugPrint(
                                'DND policy not granted -> using appSilentMode fallback');
                            return;
                          }
                          // Set to silent only if not already silent
                          if (filter != null &&
                              filter != Dnd.interruptionFilterNone) {
                            try {
                              await Dnd.setInterruptionFilter(
                                  Dnd.interruptionFilterNone);
                              debugPrint(
                                  'DND set to silent (previous=$filter)');
                            } catch (e) {
                              debugPrint('Failed to set system DND: $e');
                              NotificationService.appSilentMode = true;
                            }
                            // Start a minimal foreground service to reduce chance of
                            // the OS killing the app while a long timer runs.
                            Dnd.startForegroundService().then((ok) {
                              if (ok) debugPrint('Foreground service started');
                            });
                          } else if (filter == null) {
                            try {
                              await Dnd.setInterruptionFilter(
                                  Dnd.interruptionFilterNone);
                              debugPrint(
                                  'DND set to silent (previous unknown)');
                            } catch (e) {
                              debugPrint('Failed to set system DND: $e');
                              NotificationService.appSilentMode = true;
                            }
                            // Try to pin the app while work session is active.
                            Dnd.startLockTask().then((ok) {
                              if (ok) {
                                debugPrint('Lock task started');
                              } else {
                                debugPrint(
                                    'Lock task not started or unsupported');
                              }
                            });
                            // Also request a foreground service for persistence.
                            Dnd.startForegroundService().then((ok) {
                              if (ok) debugPrint('Foreground service started');
                            });
                          } else {
                            debugPrint('DND already silent, nothing to do');
                          }
                        });
                      }
                    } else if (Platform.isIOS) {
                      // iOS: mostrar mensaje informativo
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Modo DND no soportado automáticamente en iOS.')),
                      );
                    }
                  }
                  // Restaurar DND al finalizar sesión
                  if (state is TimerCompleted) {
                    if (Platform.isAndroid && _previousDndFilter != null) {
                      Dnd.setInterruptionFilter(_previousDndFilter!).then((_) {
                        debugPrint(
                            'DND restored to $_previousDndFilter after completion');
                      });
                      _previousDndFilter = null;
                      // Stop lock task on completion
                      Dnd.stopLockTask().then((ok) {
                        if (ok) {
                          debugPrint('Lock task stopped after completion');
                        }
                      });
                      // Stop foreground service when finished
                      Dnd.stopForegroundService().then((ok) {
                        if (ok) debugPrint('Foreground service stopped');
                      });
                    }
                  }
                  if (state is TimerRunInProgress) {
                    final sec = state.remaining;
                    final isWorkPhase = state.phase == TimerPhase.work;
                    // Manage ticking sound start/stop
                    if (_tickingEnabled) {
                      if (!state.paused && isWorkPhase) {
                        _ensureTicking();
                      } else {
                        _stopTicking();
                      }
                    }
                    if (sec != _lastNotifSecond) {
                      // update at most once per second
                      _lastNotifSecond = sec;
                      SessionRepository()
                          .isPersistentNotificationEnabled()
                          .then((enabled) {
                        if (enabled) {
                          // Send a tiny update to the native foreground service
                          // to avoid rebuilding complex notification objects every second.
                          Dnd.updateForegroundNotification(
                            remainingSeconds: state.remaining,
                            paused: state.paused,
                            isWork: state.phase == TimerPhase.work,
                            title: state.phase == TimerPhase.work
                                ? loc.phaseWorkTitle
                                : loc.phaseBreakTitle,
                          );
                        }
                      });
                    }
                    // Haptic feedback on pause/resume toggle (only when change detected)
                    if (state.paused) {
                      final now = DateTime.now().millisecondsSinceEpoch;
                      if (now - _lastHapticToggleStamp > 600) {
                        HapticFeedback.lightImpact();
                        _lastHapticToggleStamp = now;
                      }
                    }
                    // Last 5 seconds alert (once)
                    if (sec <= 5 && !_last5AlertPlayed) {
                      _repo.isLast5AlertEnabled().then((enabled) {
                        if (enabled && !_last5AlertPlayed) {
                          _last5AlertPlayed = true;
                          HapticFeedback.mediumImpact();
                          _stopTicking(); // avoid overlap
                          // ignore: discarded_futures
                          _playLast5Sound();
                          _startFlash();
                        }
                      });
                    }
                    if (sec > 5) {
                      _last5AlertPlayed = false; // reset for next cycle
                      _stopFlash();
                      if (_tickingEnabled && !state.paused && isWorkPhase) {
                        _ensureTicking();
                      }
                    }
                  } else if (state is TimerCompleted) {
                    _stopTicking();
                    final totalSessions = state.totalSessions;
                    final workDur = state.workDuration;
                    final xpEarned = (workDur / 60 * state.session).round();
                    GamificationService.instance.awardXP(xpEarned);
                    MomentumService.instance.recordSessionToday();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => SessionSummaryScreen(
                          totalSessions: totalSessions,
                          workMinutesPerSession: workDur ~/ 60,
                          earnedXP: xpEarned,
                        ),
                      ),
                    );

                    // Calendar Export Integration
                    final endTime = DateTime.now();
                    final startTime = endTime.subtract(
                        Duration(seconds: workDur * state.totalSessions));
                    CalendarService.instance.exportSession(
                        startTime: startTime,
                        endTime: endTime,
                        title: 'Sesión de Enfoque (Pomodoro)',
                        description:
                            'Sesión productiva en la app Pomodoro. Ganaste $xpEarned XP.');

                    NotificationService.showTimerFinishedNotification(
                      id: 1000,
                      title: loc.sessionCompleted,
                      body:
                          'Completaste $totalSessions sesiones! +$xpEarned XP',
                    );
                  } else if (state is TimerInitial) {
                    // Restore DND if user reset/cancelled
                    if (Platform.isAndroid && _previousDndFilter != null) {
                      Dnd.setInterruptionFilter(_previousDndFilter!);
                      debugPrint(
                          'DND restored to $_previousDndFilter on initial/reset');
                      _previousDndFilter = null;
                      // Stop any active lock task when user resets
                      Dnd.stopLockTask().then((ok) {
                        if (ok) debugPrint('Lock task stopped on reset');
                      });
                      // Ensure foreground service stopped on reset
                      Dnd.stopForegroundService().then((ok) {
                        if (ok) {
                          debugPrint('Foreground service stopped on reset');
                        }
                      });
                    }
                  }
                },
                builder: (context, state) {
                  if (state is TimerInitial) {
                    return Center(
                        child: Text(AppLocalizations.of(context).timerReady,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)));
                  } else if (state is TimerRunInProgress) {
                    final loc = AppLocalizations.of(context);
                    final isWork = state.phase == TimerPhase.work;
                    final percent = isWork
                        ? state.remaining / state.workDuration
                        : state.remaining / state.breakDuration;
                    final remaining = state.remaining;
                    final phaseLabel = isWork
                        ? '${widget.focusMode.emoji}  ${widget.focusMode.name}'
                        : '☕  Descanso';
                    final sessionLabel =
                        'Sesión ${state.session} de ${state.totalSessions}';

                    final phaseColor = isWork
                        ? widget.focusMode.color
                        : const Color(0xFF4ECDC4);

                    _initPulse();
                    final pulseVal = _pulseController?.value ?? 0.0;

                    return Column(
                      children: [
                        const SizedBox(height: 8),

                        // Phase header pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: phaseColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: phaseColor.withValues(alpha: 0.4),
                                width: 1),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              phaseLabel,
                              key: ValueKey(state.phase),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: phaseColor,
                                  letterSpacing: 0.3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(sessionLabel,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4))),

                        // Orb + time
                        Expanded(
                          child: Center(
                            child: _FocusOrb(
                              percent: percent,
                              timeText: _format(remaining),
                              color: phaseColor,
                              pulseFactor: pulseVal,
                              paused: state.paused,
                            ),
                          ),
                        ),

                        // Goal progress
                        if (_todayGoalRemaining >= 0 && _dailyGoalMinutes > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _GoalProgressBar(
                              goalMinutes: _dailyGoalMinutes,
                              remaining: _todayGoalRemaining,
                              color: phaseColor,
                            ),
                          ),

                        // Task title (if assigned)
                        if (widget.taskTitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.taskTitle!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Break activity suggestion
                        if (!isWork)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: _BreakActivityCard(
                              activity: BreakActivity.forBreakMinutes(
                                  state.breakDuration ~/ 60),
                              color: phaseColor,
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  icon: state.paused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  label: state.paused
                                      ? loc.resume
                                      : loc.pause,
                                  color: phaseColor,
                                  primary: true,
                                  onTap: () => context.read<TimerBloc>().add(
                                      state.paused
                                          ? TimerResumed()
                                          : TimerPaused()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _ActionButton(
                                icon: Icons.skip_next_rounded,
                                label: loc.skip,
                                color: phaseColor,
                                primary: false,
                                onTap: () => context
                                    .read<TimerBloc>()
                                    .add(TimerPhaseCompleted()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  } else if (state is TimerCompleted) {
                    return const SizedBox(); // navegamos via listener
                  }
                  return const SizedBox();
                },
              ),
            ),
            flashOverlay, // Overlay on top
          ],
        ),
      ),
    );
  }

  Future<void> _ensureTicking() async {
    // Delegate to shared AudioService
    try {
      await AudioService.instance.startTicking();
    } catch (e) {
      debugPrint('Ticking start failed: $e');
    }
  }

  Future<void> _stopTicking() async {
    try {
      await AudioService.instance.stopTicking();
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New visual widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FocusOrb extends StatelessWidget {
  final double percent;
  final String timeText;
  final Color color;
  final double pulseFactor;
  final bool paused;

  const _FocusOrb({
    required this.percent,
    required this.timeText,
    required this.color,
    required this.pulseFactor,
    required this.paused,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final pulse = paused ? 1.0 : (0.96 + pulseFactor * 0.04);
    final orbSize = 220.0 * pulse;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: orbSize + 40,
          height: orbSize + 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: paused ? 0.08 : 0.18),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
        // Progress arc
        SizedBox(
          width: orbSize,
          height: orbSize,
          child: CustomPaint(
            painter: _OrbPainter(
              percent: percent,
              color: color,
              isDark: isDark,
            ),
          ),
        ),
        // Time text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale:
                      Tween(begin: 0.92, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                timeText,
                key: ValueKey(timeText),
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w300,
                  color: textColor,
                  letterSpacing: -2,
                ),
              ),
            ),
            if (paused) ...[
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('PAUSADO',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 1.5)),
              ),
            ]
          ],
        ),
      ],
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double percent;
  final Color color;
  final bool isDark;

  _OrbPainter({
    required this.percent,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;

    // Track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.1 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * pi * percent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweep,
      false,
      arcPaint,
    );

    // Inner subtle fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.06 : 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 3, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.percent != percent || old.color != color;
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool primary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = primary
        ? color
        : (isDark
            ? color.withValues(alpha: 0.12)
            : color.withValues(alpha: 0.08));
    final fgColor = primary ? Colors.white : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: primary
              ? null
              : Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fgColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.0),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalProgressBar extends StatelessWidget {
  final int goalMinutes;
  final int remaining;
  final Color color;

  const _GoalProgressBar({
    required this.goalMinutes,
    required this.remaining,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = (goalMinutes - remaining).clamp(0, goalMinutes);
    final pct = goalMinutes == 0 ? 0.0 : done / goalMinutes;
    final subColor =
        isDark ? const Color(0xFF8A8AB0) : const Color(0xFF6B6B8A);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: pct.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context).goalProgressLabel(done, goalMinutes),
          style: TextStyle(fontSize: 11, color: subColor),
        ),
      ],
    );
  }
}

class _BreakActivityCard extends StatelessWidget {
  final BreakActivity activity;
  final Color color;

  const _BreakActivityCard({required this.activity, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2E2E4A) : const Color(0xFFE0E0F0);
    final textColor =
        isDark ? const Color(0xFFEEEEF6) : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8A8AB0) : const Color(0xFF6B6B8A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text(activity.emoji,
                    style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor)),
                const SizedBox(height: 2),
                Text(activity.description,
                    style: TextStyle(fontSize: 12, color: subColor),
                    maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
