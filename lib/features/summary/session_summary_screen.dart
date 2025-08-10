import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
import 'package:pomodoro/core/widgets/focus_weekly_chart.dart';

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
    return FutureBuilder(
      future: Future.wait([
        repo.todayWorkSeconds(),
        repo.workSecondsByDayLast7(),
        repo.getDailyGoalMinutes(),
        repo.todayProgress(),
      ]),
      builder: (context, snap) {
        Widget body;
        if (!snap.hasData) {
          body = const Center(child: CircularProgressIndicator());
        } else {
          final todaySeconds = snap.data![0] as int;
          final map = snap.data![1] as Map<String, int>;
          final goalMinutes = snap.data![2] as int;
          final progress = snap.data![3] as double;
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(t.sessionCompleted,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  'Total: ${widget.totalSessions} x ${widget.workMinutesPerSession} min',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.greenAccent)),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: _shareKey,
                child: Card(
                  color: Colors.black,
                  shadowColor: Colors.greenAccent,
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(t.todayProgress,
                            style: const TextStyle(
                                color: Colors.greenAccent, fontSize: 18)),
                        const SizedBox(height: 12),
                        Text(_formatMinutes(todaySeconds),
                            style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 32,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          backgroundColor:
                              Colors.greenAccent.withValues(alpha: 0.15),
                          color: Colors.greenAccent,
                          minHeight: 6,
                        ),
                        const SizedBox(height: 8),
                        Text(t.dailyGoal(goalMinutes),
                            style: const TextStyle(
                                color: Colors.greenAccent, fontSize: 12)),
                        const SizedBox(height: 12),
                        FocusWeeklyChart(data: map),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(t.last7Days,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Colors.greenAccent, fontSize: 18)),
              const Spacer(),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(t.newSession),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  final totalMin =
                      (widget.totalSessions * widget.workMinutesPerSession);
                  Share.share(
                      '🔥 Pomodoro: $totalMin min (${_formatMinutes(todaySeconds)})');
                },
                icon: const Icon(Icons.share, color: Colors.greenAccent),
                label: Text(t.share,
                    style: const TextStyle(color: Colors.greenAccent)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.greenAccent)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _sharing
                    ? null
                    : () => _shareImage(todaySeconds, goalMinutes),
                child: _sharing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(t.shareImage,
                        style: const TextStyle(color: Colors.greenAccent)),
              ),
              const SizedBox(height: 16),
            ],
          );
        }
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: body)),
        );
      },
    );
  }
}
