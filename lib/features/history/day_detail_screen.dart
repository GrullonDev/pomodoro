import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pomodoro/l10n/app_localizations.dart';

class DayDetailScreen extends StatelessWidget {
  final DateTime day;
  final int seconds;
  const DayDetailScreen({super.key, required this.day, required this.seconds});

  String _formatFocusTime(int s) {
    if (s < 3600) {
      return '${(s / 60).floor()}m';
    }
    final h = (s / 3600).floor();
    final m = ((s % 3600) / 60).floor();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final accentColor = scheme.primary;

    final formatter = DateFormat('EEEE, d MMMM y', Localizations.localeOf(context).toString());
    final dateStr = formatter.format(day);
    final simpleDate = '${day.year}-${day.month}-${day.day}';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          t.dayDetailTitle,
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.05),
                  border: Border.all(color: accentColor.withValues(alpha: 0.1), width: 1),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'day_total_$simpleDate',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            _formatFocusTime(seconds),
                            style: GoogleFonts.outfit(
                              color: accentColor,
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -2,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        t.totalFocus.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_note_rounded, color: accentColor, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha de la sesión',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurface.withValues(alpha: 0.5)),
                            ),
                            Text(
                              dateStr.substring(0, 1).toUpperCase() + dateStr.substring(1),
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
