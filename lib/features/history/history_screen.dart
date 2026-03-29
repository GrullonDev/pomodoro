import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/features/history/day_detail_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<List<_DayEntry>> _load() async {
    final repo = SessionRepository();
    final map = await repo.workSecondsByDayLast7();
    final entries = map.entries.where((e) => e.value > 0).map((e) {
      final parts = e.key.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return _DayEntry(DateTime(y, m, d), e.value);
    }).toList()
      ..sort((a, b) => b.day.compareTo(a.day));
    return entries;
  }

  String _formatHours(int seconds) {
    if (seconds < 3600) {
      return '${(seconds / 60).floor()}m';
    }
    final h = (seconds / 3600).floor();
    final m = ((seconds % 3600) / 60).floor();
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final accentColor = scheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          t.history,
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : accentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<_DayEntry>>(
        future: _load(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snap.data!;
          final totalSeconds = items.fold<int>(0, (p, e) => p + e.seconds);

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.3,
                    child: Icon(Icons.history_toggle_off_rounded,
                        size: 80, color: scheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.noHistory,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Summary Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2A2D3E), const Color(0xFF1B1D29)]
                            : [accentColor.withValues(alpha: 0.05), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen semanal'.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatHours(totalSeconds),
                              style: GoogleFonts.outfit(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 8),
                              child: Text(
                                'enfocados',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: scheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Has completado sesiones en ${items.length} días.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Daily Breakdown Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(
                    'Días Recientes',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ),

              // History List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final e = items[i];
                      final formatter = DateFormat('EEEE, d MMM',
                          Localizations.localeOf(context).toString());
                      final dateStr = formatter.format(e.day);
                      final simpleDate = '${e.day.year}-${e.day.month}-${e.day.day}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 500),
                              pageBuilder: (_, a, __) => FadeTransition(
                                opacity: a,
                                child: DayDetailScreen(day: e.day, seconds: e.seconds),
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: scheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        offset: const Offset(0, 4),
                                        blurRadius: 10,
                                      )
                                    ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.calendar_today_rounded,
                                      size: 18, color: accentColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateStr.substring(0, 1).toUpperCase() +
                                            dateStr.substring(1),
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Hero(
                                  tag: 'day_total_$simpleDate',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      _formatHours(e.seconds),
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded,
                                    size: 20, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
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
