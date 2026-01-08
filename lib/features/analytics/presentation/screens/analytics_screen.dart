import 'package:flutter/material.dart';
import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/features/history/history_screen.dart';
import 'package:pomodoro/features/analytics/presentation/widgets/contribution_heatmap.dart';
import 'package:pomodoro/utils/app.dart';
import 'package:pomodoro/utils/glass_container.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _repo = SessionRepository();
  bool _loading = true;
  int _totalMinutes = 0;
  Map<String, int> _weeklyData = {};
  Map<DateTime, int> _heatmapData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sessions = await _repo.loadSessions();
    final weekly =
        await _repo.workSecondsByDayLast7(); // returns string keys yyyy-mm-dd

    // Process Total
    final totalSec = sessions.fold(0, (sum, s) => sum + s.workSeconds);

    // Process Heatmap
    final heatmap = <DateTime, int>{};
    for (var s in sessions) {
      // Normalize to midnight
      final d = DateTime(s.endTime.year, s.endTime.month, s.endTime.day);
      heatmap[d] = (heatmap[d] ?? 0) + (s.workSeconds ~/ 60);
    }

    if (mounted) {
      setState(() {
        _totalMinutes = totalSec ~/ 60;
        _weeklyData = weekly;
        _heatmapData = heatmap;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Estadísticas',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.list),
              tooltip: 'Ver Historial',
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryScreen()));
              },
            )
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCard(context),
                    const SizedBox(height: 20),
                    _buildWeeklyChart(context),
                    const SizedBox(height: 20),
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: ContributionHeatmap(dataset: _heatmapData),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('Tiempo Total de Enfoque',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            '${(_totalMinutes / 60).toStringAsFixed(1)} h',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          Text('$_totalMinutes mins acumulados',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)))
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context) {
    final maxVal = _weeklyData.values.isEmpty
        ? 60
        : _weeklyData.values.reduce((a, b) => a > b ? a : b);
    // Safety for 0 division
    final maxScale = maxVal > 0 ? maxVal.toDouble() : 60.0;

    // Keys are yyyy-mm-dd
    final sortedKeys = _weeklyData.keys.toList()..sort();

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Últimos 7 Días',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sortedKeys.map((k) {
                final seconds = _weeklyData[k] ?? 0;
                // If I use minutes for display chart height.
                final heightFactor = (seconds / maxScale).clamp(0.0, 1.0);

                // Parse date for label
                final dateParts = k.split('-');
                final dayLabel = dateParts.length == 3
                    ? '${dateParts[2]}/${dateParts[1]}'
                    : '';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${(seconds / 60).round()}',
                        style: const TextStyle(fontSize: 10)),
                    const SizedBox(height: 4),
                    Container(
                      width: 12,
                      height: 100 * heightFactor +
                          10, // Min height 10 for visibility
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(dayLabel, style: const TextStyle(fontSize: 10)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
