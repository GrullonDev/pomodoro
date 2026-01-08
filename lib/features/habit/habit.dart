import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importar para usar FilteringTextInputFormatter
import 'package:pomodoro/utils/responsive/responsive.dart';
import 'package:pomodoro/utils/glass_container.dart';

import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/timer/timer_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';

class Habit extends StatefulWidget {
  const Habit({super.key});

  @override
  State<Habit> createState() => _HabitState();
}

class _HabitState extends State<Habit> {
  final TextEditingController workController = TextEditingController();
  final TextEditingController breakController = TextEditingController();
  final TextEditingController sessionController = TextEditingController();
  final TextEditingController goalController = TextEditingController();
  final repo = SessionRepository();

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final goal = await repo.getDailyGoalMinutes();
    if (mounted) goalController.text = goal.toString();
  }

  void _applyPreset(int work, int brk, int sess) {
    workController.text = work.toString();
    breakController.text = brk.toString();
    sessionController.text = sess.toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    // Responsive Logic
    final double horizontalMargin = isMobile ? 12 : 30;
    final double containerPadding = isMobile ? 20 : 30;

    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // More legible text colors
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = textColor.withOpacity(0.7);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            title: Text(t.habitTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? Colors.white : scheme.primary.withOpacity(0.8),
                  fontFamily: 'Arial',
                ))),
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalMargin, vertical: 20),
            child: Column(
              children: [
                _GlassSection(
                  padding: containerPadding,
                  children: [
                    Text(
                      t.workDurationLabel,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: labelColor),
                    ),
                    const SizedBox(height: 12),
                    _GlassInput(
                      controller: workController,
                      hint: t.minutesHint,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      t.breakDurationLabel,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: labelColor),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _GlassInput(
                                controller: breakController,
                                hint: t.minutesHint,
                                isDark: isDark)),
                        if (!isMobile) ...[
                          const SizedBox(width: 20),
                          // Optional: maybe add logic here for desktop layout but keeping column is fine for now
                        ]
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      t.sessionsLabel,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: labelColor),
                    ),
                    const SizedBox(height: 12),
                    _GlassInput(
                        controller: sessionController,
                        hint: t.sessionsHint,
                        isDark: isDark),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _PresetChip(
                            label: t.presetFast,
                            onTap: () => _applyPreset(15, 3, 4)),
                        _PresetChip(
                            label: t.presetClassic,
                            onTap: () => _applyPreset(25, 5, 4)),
                        _PresetChip(
                            label: t.presetDeep,
                            onTap: () => _applyPreset(50, 10, 3)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _GlassSection(
                  padding: containerPadding,
                  children: [
                    Text(
                      t.dailyGoalLabel,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: labelColor),
                    ),
                    const SizedBox(height: 12),
                    _GlassInput(
                      controller: goalController,
                      hint: t.dailyGoalHint,
                      isDark: isDark,
                      onChanged: (v) {
                        final m = int.tryParse(v);
                        if (m != null) repo.setDailyGoalMinutes(m);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 700),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return FadeTransition(
                              opacity: animation,
                              child: TimerScreen(
                                  workMinutes:
                                      int.tryParse(workController.text) ?? 25,
                                  breakMinutes:
                                      int.tryParse(breakController.text) ?? 5,
                                  sessions:
                                      int.tryParse(sessionController.text) ??
                                          4));
                        },
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: scheme.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Hero(
                        tag: 'timerHero',
                        child: Text(
                          t.start.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Arial',
                          ),
                        )),
                  ),
                ),

                const SizedBox(height: 30),

                // Long Break Config (Optional collapsible?)
                ExpansionTile(
                  title: Text(t.longBreakConfigTitle,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor.withOpacity(0.8))),
                  collapsedIconColor: scheme.primary,
                  iconColor: scheme.primary,
                  children: [
                    FutureBuilder(
                        future: Future.wait([
                          repo.getLongBreakInterval(),
                          repo.getLongBreakDurationMinutes(),
                        ]),
                        builder: (context, snap) {
                          if (!snap.hasData) return const SizedBox();
                          final interval = snap.data![0];
                          final duration = snap.data![1];
                          return _GlassSection(
                            padding: 15,
                            children: [
                              Text(t.longBreakIntervalLabel,
                                  style: TextStyle(
                                      color: labelColor, fontSize: 13)),
                              Slider(
                                value: interval.toDouble(),
                                min: 2,
                                max: 8,
                                divisions: 6,
                                label: interval.toString(),
                                activeColor: scheme.primary,
                                onChanged: (v) async {
                                  await repo.setLongBreakInterval(v.round());
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 10),
                              Text(t.longBreakDurationLabel,
                                  style: TextStyle(
                                      color: labelColor, fontSize: 13)),
                              Slider(
                                value: duration.toDouble(),
                                min: 5,
                                max: 30,
                                divisions: 5,
                                label: duration.toString(),
                                activeColor: scheme.primary,
                                onChanged: (v) async {
                                  await repo
                                      .setLongBreakDurationMinutes(v.round());
                                  setState(() {});
                                },
                              ),
                            ],
                          );
                        })
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final List<Widget> children;
  final double padding;
  const _GlassSection({required this.children, required this.padding});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: children,
      ),
    );
  }
}

class _GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final Function(String)? onChanged;

  const _GlassInput({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        onChanged: onChanged,
        style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+$')),
        ],
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.3)),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: scheme.primary, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: scheme.primary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
