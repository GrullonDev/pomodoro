import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/widgets/focus_weekly_chart.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
import 'package:pomodoro/utils/app.dart';
import 'package:pomodoro/utils/glass_container.dart';

class SessionSummaryScreen extends StatefulWidget {
  final int totalSessions;
  final int workMinutesPerSession;
  const SessionSummaryScreen(
      {super.key,
      required this.totalSessions,
      required this.workMinutesPerSession});

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  final GlobalKey _shareKey = GlobalKey();
  bool _sharing = false;

  String _formatMinutes(int seconds) => '${(seconds / 60).round()}m';

  Future<void> _shareImage(int todaySeconds, int goalMinutes) async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/summary_share.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Pomodoro Focus');
    } catch (_) {
      // ignore error
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = SessionRepository();
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedGradientShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: FutureBuilder(
            future: Future.wait([
              repo.todayWorkSeconds(),
              repo.workSecondsByDayLast7(),
              repo.getDailyGoalMinutes(),
              repo.todayProgress(),
            ]),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final todaySeconds = snap.data![0] as int;
              final map = snap.data![1] as Map<String, int>;
              final goalMinutes = snap.data![2] as int;
              final progress = snap.data![3] as double;

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    // Icon & Title
                    Icon(Icons.check_circle_outline_rounded,
                        size: 80, color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      t.sessionCompleted,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.totalSessions} sesiones • ${widget.totalSessions * widget.workMinutesPerSession} min total',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Main Stats Card
                    RepaintBoundary(
                      key: _shareKey,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              t.todayProgress.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                letterSpacing: 1.5,
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _formatMinutes(todaySeconds),
                                  style:
                                      theme.textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '/ ${goalMinutes}m',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color:
                                        scheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor:
                                    scheme.onSurface.withValues(alpha: 0.1),
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 100,
                              child: FocusWeeklyChart(data: map),
                            )
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context)
                                .popUntil((r) => r.isFirst),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              t.newSession,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final totalMin = (widget.totalSessions *
                                  widget.workMinutesPerSession);
                              Share.share(
                                '🔥 Pomodoro: $totalMin min (${_formatMinutes(todaySeconds)})',
                              );
                            },
                            icon: const Icon(Icons.share_rounded, size: 20),
                            label: Text(t.share),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.onSurface,
                              side: BorderSide(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.2)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _sharing
                                ? null
                                : () => _shareImage(todaySeconds, goalMinutes),
                            icon: _sharing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.image_outlined, size: 20),
                            label: Text(t.shareImage),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.onSurface,
                              side: BorderSide(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.2)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
