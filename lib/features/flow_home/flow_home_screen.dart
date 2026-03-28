import 'package:flutter/material.dart';
import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/data/task_repository.dart';
import 'package:pomodoro/core/domain/entities/task.dart';
import 'package:pomodoro/core/timer/timer_screen.dart';
import 'package:pomodoro/features/focus_modes/focus_mode.dart';
import 'package:pomodoro/features/momentum/momentum_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FlowHomeScreen extends StatefulWidget {
  const FlowHomeScreen({super.key});

  @override
  State<FlowHomeScreen> createState() => _FlowHomeScreenState();
}

class _FlowHomeScreenState extends State<FlowHomeScreen> {
  FocusMode _selectedMode = FocusMode.sprint;
  List<TaskItem> _pendingTasks = [];
  int _todayMin = 0;
  int _goalMin = 120;

  static const _selectedModeKey = 'selected_focus_mode_id';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeId = prefs.getString(_selectedModeKey) ?? FocusMode.sprint.id;

    final repo = SessionRepository();
    final taskRepo = TaskRepository();
    final allTasks = await taskRepo.all();
    final goal = await repo.getDailyGoalMinutes();
    final todaySec = await repo.todayWorkSeconds();

    if (!mounted) return;
    setState(() {
      _selectedMode = FocusMode.fromId(modeId);
      _pendingTasks = allTasks.where((t) => !t.done).toList();
      _goalMin = goal;
      _todayMin = (todaySec / 60).floor();
    });
  }

  Future<void> _selectMode(FocusMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedModeKey, mode.id);
    if (mounted) setState(() => _selectedMode = mode);
  }

  void _startTimer() {
    final task = _pendingTasks.isNotEmpty ? _pendingTasks.first : null;
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: TimerScreen(
            workMinutes: _selectedMode.workMinutes,
            breakMinutes: _selectedMode.breakMinutes,
            sessions: _selectedMode.sessions,
            task: task,
            focusMode: _selectedMode,
          ),
        ),
      ),
    ).then((_) {
      MomentumService.instance.refresh();
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEEEEF6) : const Color(0xFF1A1A2E);
    final subColor = isDark ? const Color(0xFF8A8AB0) : const Color(0xFF6B6B8A);
    final cardBg = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E4A) : const Color(0xFFE0E0F0);

    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final dateStr = _formatDate(now);

    final progressPct = _goalMin > 0
        ? (_todayMin / _goalMin).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateStr,
                        style: TextStyle(
                            fontSize: 13,
                            color: subColor,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5)),
                    ValueListenableBuilder<int>(
                      valueListenable: MomentumService.instance.streak,
                      builder: (_, streak, __) => streak > 0
                          ? _StreakBadge(streak: streak)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(greeting,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.2)),
                const SizedBox(height: 24),

                // ── Momentum Card ──
                _MomentumCard(
                  todayMin: _todayMin,
                  goalMin: _goalMin,
                  progressPct: progressPct,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  textColor: textColor,
                  subColor: subColor,
                ),
                const SizedBox(height: 24),

                // ── Focus Mode Selector ──
                Text('MODO DE ENFOQUE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: subColor,
                        letterSpacing: 1.2)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: FocusMode.all().length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) {
                      final mode = FocusMode.all()[i];
                      final selected = mode.id == _selectedMode.id;
                      return _FocusModeCard(
                        mode: mode,
                        selected: selected,
                        onTap: () => _selectMode(mode),
                        cardBg: cardBg,
                        borderColor: borderColor,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Active Task ──
                if (_pendingTasks.isNotEmpty) ...[
                  Text('ENFÓCATE EN',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: subColor,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  _ActiveTaskCard(
                    task: _pendingTasks.first,
                    pendingCount: _pendingTasks.length,
                    mode: _selectedMode,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    subColor: subColor,
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Start Button ──
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _startTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedMode.color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_selectedMode.emoji,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(
                          'INICIAR ${_selectedMode.name.toUpperCase()}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Config details ──
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '${_selectedMode.workMinutes}min trabajo · ${_selectedMode.breakMinutes}min descanso · ${_selectedMode.sessions} sesiones',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Buenos días ☀️';
    if (hour < 18) return 'Buenas tardes 🌤';
    return 'Buenas noches 🌙';
  }

  String _formatDate(DateTime dt) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internos
// ─────────────────────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B9D).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFFF6B9D).withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$streak días',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF6B9D)),
          ),
        ],
      ),
    );
  }
}

class _MomentumCard extends StatelessWidget {
  final int todayMin;
  final int goalMin;
  final double progressPct;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subColor;

  const _MomentumCard({
    required this.todayMin,
    required this.goalMin,
    required this.progressPct,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MomentumService.instance.momentumScore,
      builder: (_, score, __) {
        final scoreColor = _scoreColor(score);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // Score circle
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: progressPct,
                        strokeWidth: 5,
                        backgroundColor: scoreColor.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$score',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: scoreColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MOMENTUM HOY',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: subColor,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(_scoreLabel(score),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    const SizedBox(height: 6),
                    Text(
                      '$todayMin min enfocados${goalMin > 0 ? ' de $goalMin meta' : ''}',
                      style: TextStyle(fontSize: 13, color: subColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF55EFC4);
    if (score >= 50) return const Color(0xFF7C6FF7);
    if (score >= 20) return const Color(0xFFFFA552);
    return const Color(0xFF8A8AB0);
  }

  String _scoreLabel(int score) {
    if (score >= 100) return '¡En llamas! 🔥';
    if (score >= 80) return 'Excelente';
    if (score >= 60) return 'Buen ritmo';
    if (score >= 40) return 'Avanzando';
    if (score >= 20) return 'Comenzando';
    return 'Sin sesiones aún';
  }
}

class _FocusModeCard extends StatelessWidget {
  final FocusMode mode;
  final bool selected;
  final VoidCallback onTap;
  final Color cardBg;
  final Color borderColor;

  const _FocusModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEEEEF6) : const Color(0xFF1A1A2E);
    final subColor = isDark ? const Color(0xFF8A8AB0) : const Color(0xFF6B6B8A);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? mode.color.withValues(alpha: isDark ? 0.2 : 0.12)
              : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? mode.color : borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mode.emoji,
                style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(mode.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? mode.color : textColor)),
            const SizedBox(height: 2),
            Text('${mode.workMinutes}m',
                style: TextStyle(fontSize: 10, color: subColor)),
          ],
        ),
      ),
    );
  }
}

class _ActiveTaskCard extends StatelessWidget {
  final TaskItem task;
  final int pendingCount;
  final FocusMode mode;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subColor;

  const _ActiveTaskCard({
    required this.task,
    required this.pendingCount,
    required this.mode,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: mode.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(mode.emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${task.sessionsCompleted}/${task.sessions} sesiones'
                  '${pendingCount > 1 ? ' · +${pendingCount - 1} más' : ''}',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subColor),
        ],
      ),
    );
  }
}
