import 'package:flutter/material.dart';

import 'package:pomodoro/l10n/app_localizations.dart';

class DayDetailScreen extends StatelessWidget {
  final DateTime day;
  final int seconds;
  const DayDetailScreen({super.key, required this.day, required this.seconds});

  String _fmt(int s) => '${(s / 60).round()}m';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dateStr =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          title:
              Text(t.dayDetailTitle, style: TextStyle(color: scheme.primary))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(dateStr,
                style: TextStyle(color: scheme.primary, fontSize: 18)),
            const SizedBox(height: 20),
            Hero(
              tag: 'day_total_$dateStr',
              child: Text(_fmt(seconds),
                  style: TextStyle(
                      color: scheme.primary,
                      fontSize: 64,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(t.totalFocus,
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
