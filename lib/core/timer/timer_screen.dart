import 'dart:async';
import 'dart:math'; // used for sine wave generation
import 'dart:typed_data';

// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/timer/ticker.dart';
import 'package:pomodoro/core/timer/timer_action_bus.dart';
import 'package:pomodoro/core/timer/timer_bloc.dart';
import 'package:pomodoro/features/summary/session_summary_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
import 'package:pomodoro/utils/notifications/notifications.dart';

class TimerScreen extends StatelessWidget {
  final int workMinutes;
  final int breakMinutes;
  final int sessions;
  const TimerScreen(
      {super.key,
      required this.workMinutes,
      required this.breakMinutes,
      required this.sessions});

  @override
  Widget build(BuildContext context) {
    final workSeconds = workMinutes * 60;
    final breakSeconds = breakMinutes * 60;
    return BlocProvider(
      create: (_) =>
          TimerBloc(ticker: const Ticker(), repository: SessionRepository())
            ..add(TimerStarted(
              phase: TimerPhase.work,
              duration: workSeconds,
              workDuration: workSeconds,
              breakDuration: breakSeconds,
              session: 1,
              totalSessions: sessions,
            )),
      child: const _TimerView(),
    );
  }
}

class _TimerView extends StatefulWidget {
  const _TimerView();
  @override
  State<_TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<_TimerView>
    with SingleTickerProviderStateMixin {
  late final StreamSubscription<String> _actionSub;
  int _lastNotifSecond = -1; // throttling control
  int _lastHapticToggleStamp = 0;
  bool _last5AlertPlayed = false;
  int _todayGoalRemaining = -1; // minutes remaining
  int _dailyGoalMinutes = 0;
  final _repo = SessionRepository();
  AnimationController? _pulseController; // nullable for hot reload safety
  late final AudioPlayer _audioPlayer;
  bool _flashing = false;
  Timer? _flashTimer;
  bool _flashEnabled = true;
  bool _soundEnabled = true;
  bool _audioPreloaded = false;
  Uint8List? _generatedBeep; // fallback bytes if asset missing

  String _format(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _initPulse();
    _audioPlayer = AudioPlayer();
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
    // Preload audio (fire & forget)
    () async {
      try {
        await _audioPlayer.setSource(AssetSource('sounds/last5.mp3'));
        _audioPreloaded = true;
      } catch (e) {
        debugPrint('Audio preload failed: $e');
        // Fallback: generate a beep in memory so feature still works
        _generatedBeep = _generateBeepWav();
        try {
          await _audioPlayer.setSource(BytesSource(_generatedBeep!));
          _audioPreloaded = true;
        } catch (e2) {
          debugPrint('Beep generation also failed: $e2');
        }
      }
    }();
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
    _actionSub.cancel();
    _pulseController?.dispose();
    _flashTimer?.cancel();
    _audioPlayer.dispose();
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
      if (!_audioPreloaded) {
        try {
          await _audioPlayer.setSource(AssetSource('sounds/last5.mp3'));
          _audioPreloaded = true;
        } catch (_) {
          _generatedBeep ??= _generateBeepWav();
          await _audioPlayer.setSource(BytesSource(_generatedBeep!));
          _audioPreloaded = true;
        }
      }
      await _audioPlayer.stop();
      _audioPlayer.setVolume(0.8);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Play sound failed: $e');
    }
  }

  // Generate a 500ms mono 44.1kHz 440Hz sine beep WAV in memory
  Uint8List _generateBeepWav({
    double freq = 440,
    int sampleRate = 44100,
    int millis = 500,
  }) {
    final sampleCount = (sampleRate * millis / 1000).round();
    final bytes = BytesBuilder();
    final data = BytesBuilder();
    for (int i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final sample = (sin(2 * pi * freq * t) * 0.4); // amplitude 0.4
      final s = (sample * 32767).clamp(-32768, 32767).toInt();
      data.addByte(s & 0xFF);
      data.addByte((s >> 8) & 0xFF);
    }
    final dataBytes = data.toBytes();
    final totalDataLen = dataBytes.length + 36;
    // RIFF header
    final header = BytesBuilder();
    void writeString(String s) => header.add(s.codeUnits);
    void write32(int v) => header.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);
    void write16(int v) => header.add([v & 0xFF, (v >> 8) & 0xFF]);
    writeString('RIFF');
    write32(totalDataLen);
    writeString('WAVE');
    writeString('fmt ');
    write32(16); // PCM chunk size
    write16(1); // PCM
    write16(1); // channels
    write32(sampleRate);
    write32(sampleRate * 2); // byte rate
    write16(2); // block align
    write16(16); // bits per sample
    writeString('data');
    write32(dataBytes.length);
    bytes.add(header.toBytes());
    bytes.add(dataBytes);
    return bytes.toBytes();
  }

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
        _flashing ? Colors.greenAccent.withOpacity(0.10) : Colors.black;
    return AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: _flashing ? 0.92 : 1.0,
        child: Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(AppLocalizations.of(context).appTitle,
                style: const TextStyle(color: Colors.greenAccent)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.greenAccent),
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
                  if (state is TimerRunInProgress) {
                    final sec = state.remaining;
                    if (sec != _lastNotifSecond) {
                      // update at most once per second
                      _lastNotifSecond = sec;
                      SessionRepository()
                          .isPersistentNotificationEnabled()
                          .then((enabled) {
                        if (enabled) {
                          NotificationService.updateChronoRemaining(
                            remaining: Duration(seconds: state.remaining),
                            isWork: state.phase == TimerPhase.work,
                            paused: state.paused,
                            phaseTitle: state.phase == TimerPhase.work
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
                          // ignore: discarded_futures
                          _playLast5Sound();
                          _startFlash();
                        }
                      });
                    }
                    if (sec > 5) {
                      _last5AlertPlayed = false; // reset for next cycle
                      _stopFlash();
                    }
                  } else if (state is TimerCompleted) {
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
                    // no-op
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
            backgroundColor: barColor.withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation(barColor),
          ),
        ),
        const SizedBox(height: 4),
        Text(AppLocalizations.of(context).goalProgressLabel(done, goalMinutes),
            style: TextStyle(fontSize: 12, color: barColor.withOpacity(0.9)))
      ],
    );
  }
}
