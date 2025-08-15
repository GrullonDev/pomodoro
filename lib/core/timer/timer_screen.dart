import 'dart:async';
import 'dart:io';
// dart:math/typed_data once used for in-file beep generation; now moved to AudioService

// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// audio handled by AudioService singleton
import 'package:pomodoro/utils/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pomodoro/utils/dnd.dart';
import 'package:pomodoro/utils/notifications/notifications.dart';

import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/data/preset_profile.dart';
import 'package:pomodoro/core/timer/ticker.dart';
import 'package:pomodoro/core/timer/timer_action_bus.dart';
import 'package:pomodoro/core/timer/timer_bloc.dart';
import 'package:pomodoro/core/data/task_repository.dart';
import 'package:pomodoro/core/domain/entities/task.dart';
import 'package:pomodoro/features/summary/session_summary_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';

class TimerScreen extends StatelessWidget {
  final int workMinutes;
  final int breakMinutes;
  final int sessions;
  final TaskItem? task; // tarea asociada (opcional)
  const TimerScreen(
      {super.key,
      required this.workMinutes,
      required this.breakMinutes,
      required this.sessions,
      this.task});

  @override
  Widget build(BuildContext context) {
    // Resolve selected preset asynchronously and fall back to provided values
    return FutureBuilder<String?>(
      future: SessionRepository().getSelectedPreset(),
      builder: (ctx, snap) {
        int work = workMinutes;
        int br = breakMinutes;
        if (snap.hasData && snap.data != null) {
          final key = snap.data!;
          if (key != 'custom') {
            final p = PresetProfile.defaults().firstWhere((e) => e.key == key,
                orElse: () => PresetProfile.custom);
            work = p.workMinutes;
            br = p.shortBreakMinutes;
          }
        }
        final workSeconds = work * 60;
        final breakSeconds = br * 60;
        return BlocProvider(
          create: (_) => TimerBloc(
                ticker: const Ticker(),
                repository: SessionRepository(),
                onTaskCycleCompleted: task == null
                    ? null
                    : () async {
                        final repo = TaskRepository();
                        if (task!.id.isNotEmpty) {
                          // marcar completada (ya terminó todas sus sesiones)
                          await repo.markDone(task!.id);
                        }
                      },
              )
                ..add(TimerStarted(
                  phase: TimerPhase.work,
                  duration: workSeconds,
                  workDuration: workSeconds,
                  breakDuration: breakSeconds,
                  session: 1,
                  totalSessions: task?.sessions ?? sessions,
                )),
          child: const _TimerView(),
        );
      },
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
  const _TimerView();
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
    final background =
        _flashing ? Colors.greenAccent.withValues(alpha: 0.10) : Colors.black;
    return AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: _flashing ? 0.92 : 1.0,
        child: Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(AppLocalizations.of(context).appTitle,
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh,
                    color: Theme.of(context).colorScheme.primary),
                onPressed: () => context.read<TimerBloc>().add(TimerReset()),
              )
            ],
          ),
          body: SafeArea(
            child: Center(
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
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => SessionSummaryScreen(
                          totalSessions: totalSessions,
                          workMinutesPerSession: workDur ~/ 60,
                        ),
                      ),
                    );
                    NotificationService.showTimerFinishedNotification(
                      id: 1000,
                      title: loc.sessionCompleted,
                      body: 'Completaste $totalSessions sesiones!',
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
                    return Text(AppLocalizations.of(context).timerReady,
                        style: const TextStyle(color: Colors.greenAccent));
                  } else if (state is TimerRunInProgress) {
                    final loc = AppLocalizations.of(context);
                    final isWork = state.phase == TimerPhase.work;
                    final percent = isWork
                        ? state.remaining / state.workDuration
                        : state.remaining / state.breakDuration;
                    final remaining = state.remaining;
                    final phaseText = isWork
                        ? loc.workPhase(state.session, state.totalSessions)
                        : loc.breakPhase;

                    return OrientationBuilder(builder: (context, orientation) {
                      const accentBase = Colors.greenAccent;
                      final alertColor = isWork
                          ? Color.lerp(accentBase, Colors.orangeAccent,
                              (1 - percent).clamp(0, 1))!
                          : accentBase;

                      _initPulse(); // ensure after hot reload
                      final pulseVal = _pulseController?.value ?? 0.0;
                      Widget ring = _ProgressRing(
                        percent: percent,
                        color: alertColor,
                        pulseFactor: isWork ? pulseVal : 0.0,
                      );

                      Widget timeCol = Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Hero(
                            tag: 'timerHero',
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                opacity: anim,
                                child: ScaleTransition(
                                    scale: Tween(begin: 0.95, end: 1.0)
                                        .animate(anim),
                                    child: child),
                              ),
                              child: Text(
                                _format(remaining),
                                key: ValueKey(remaining),
                                style: TextStyle(
                                  fontSize: orientation == Orientation.portrait
                                      ? 64
                                      : 72,
                                  color: alertColor,
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              phaseText,
                              key: ValueKey(state.phase.toString() +
                                  state.session.toString()),
                              style: TextStyle(
                                  color: alertColor,
                                  fontSize: 14,
                                  letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_todayGoalRemaining >= 0 && _dailyGoalMinutes > 0)
                            _GoalProgressBar(
                                goalMinutes: _dailyGoalMinutes,
                                remaining: _todayGoalRemaining),
                        ],
                      );

                      final buttons = Wrap(
                        spacing: 20,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          _TimerButton(
                            icon: state.paused ? Icons.play_arrow : Icons.pause,
                            label: state.paused ? loc.resume : loc.pause,
                            onTap: () => context.read<TimerBloc>().add(
                                state.paused ? TimerResumed() : TimerPaused()),
                            color: alertColor,
                          ),
                          _TimerButton(
                            icon: Icons.skip_next,
                            label: loc.skip,
                            onTap: () => context
                                .read<TimerBloc>()
                                .add(TimerPhaseCompleted()),
                            color: alertColor,
                          ),
                        ],
                      );

                      if (orientation == Orientation.portrait) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Separate ring on top
                            SizedBox(height: 220, child: Center(child: ring)),
                            const SizedBox(height: 24),
                            timeCol,
                            const SizedBox(height: 40),
                            buttons,
                            if (_todayGoalRemaining >= 0 &&
                                _dailyGoalMinutes > 0) ...[
                              const SizedBox(height: 24),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: _GoalProgressBar(
                                    goalMinutes: _dailyGoalMinutes,
                                    remaining: _todayGoalRemaining),
                              ),
                            ],
                          ],
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(child: Center(child: ring)),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    timeCol,
                                    const SizedBox(height: 40),
                                    buttons,
                                    if (_todayGoalRemaining >= 0 &&
                                        _dailyGoalMinutes > 0) ...[
                                      const SizedBox(height: 24),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24),
                                        child: _GoalProgressBar(
                                            goalMinutes: _dailyGoalMinutes,
                                            remaining: _todayGoalRemaining),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    });
                  } else if (state is TimerCompleted) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.celebration,
                            color: Colors.greenAccent, size: 100),
                        const SizedBox(height: 16),
                        Text(
                            '¡Listo! Tiempo total ${(state.workDuration / 60 * state.totalSessions).round()}m',
                            style: const TextStyle(color: Colors.greenAccent)),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Terminar'),
                        )
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ));
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

class _TimerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _TimerButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      required this.color});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.85),
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(140, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.black),
        label: Text(label,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double percent;
  final Color color;
  final double pulseFactor; // 0..1 (value of controller)
  const _ProgressRing(
      {required this.percent, required this.color, required this.pulseFactor});
  @override
  Widget build(BuildContext context) {
    final pulse = pulseFactor > 0 ? (0.95 + (pulseFactor * 0.05)) : 1.0;
    final size = 200.0 * pulse;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(percent: percent, color: color),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color color;
  _RingPainter({required this.percent, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.06;
    final rect = Offset.zero & size;
    final c = rect.center;
    final radius = (size.width - stroke) / 2;
    final bg = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawCircle(c, radius, bg);
    final sweep = 2 * 3.141592653589793 * percent;
    canvas.drawArc(Rect.fromCircle(center: c, radius: radius),
        -3.141592653589793 / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.percent != percent || old.color != color;
}

class _GoalProgressBar extends StatelessWidget {
  final int goalMinutes;
  final int remaining;
  const _GoalProgressBar({required this.goalMinutes, required this.remaining});
  @override
  Widget build(BuildContext context) {
    final done = (goalMinutes - remaining).clamp(0, goalMinutes);
    final pct = goalMinutes == 0 ? 0.0 : done / goalMinutes;
    const barColor = Colors.greenAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: pct.clamp(0, 1),
            backgroundColor: barColor.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation(barColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(AppLocalizations.of(context).goalProgressLabel(done, goalMinutes),
            style:
                TextStyle(fontSize: 12, color: barColor.withValues(alpha: 0.9)))
      ],
    );
  }
}
