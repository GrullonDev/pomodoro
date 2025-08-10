import 'package:flutter/material.dart';
import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/features/history/day_detail_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<List<_DayEntry>> _load() async {
    final repo = SessionRepository();
    final map = await repo.workSecondsByDayLast7();
    // Convert to list and sort descending by date key
    final entries = map.entries.map((e) {
      final parts = e.key.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return _DayEntry(DateTime(y, m, d), e.value);
    }).toList()
      ..sort((a, b) => b.day.compareTo(a.day));
    return entries;
  }

  String _formatMinutes(int seconds) => '${(seconds / 60).round()}m';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:
            Text(t.history, style: const TextStyle(color: Colors.greenAccent)),
      ),
      body: FutureBuilder(
        future: _load(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
              child: Text(t.noHistory,
                  style: const TextStyle(color: Colors.white54)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (context, i) {
              final e = items[i];
              final dateStr =
                  '${e.day.year}-${e.day.month.toString().padLeft(2, '0')}-${e.day.day.toString().padLeft(2, '0')}';
              return ListTile(
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    pageBuilder: (_, a, __) => FadeTransition(
                      opacity: a,
                      child: DayDetailScreen(day: e.day, seconds: e.seconds),
                    ),
                  ),
                ),
                title: Text(dateStr,
                    style: const TextStyle(color: Colors.greenAccent)),
                trailing: Hero(
                  tag: 'day_total_$dateStr',
                  child: Text(_formatMinutes(e.seconds),
                      style: const TextStyle(color: Colors.white70)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DayEntry {
  final DateTime day;
  final int seconds;
  _DayEntry(this.day, this.seconds);
}
