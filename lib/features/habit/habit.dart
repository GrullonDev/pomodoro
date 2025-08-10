import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importar para usar FilteringTextInputFormatter
import 'package:pomodoro/utils/responsive/responsive.dart';

import 'package:pomodoro/core/timer/timer_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
import 'package:pomodoro/core/data/session_repository.dart';

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

    // Definir tamaños y paddings responsivos
    final double horizontalMargin = isMobile ? 10 : 30;
    final double containerPadding = isMobile ? 10 : 20;
    final double titleFontSize = isMobile ? 22 : 28;
    final double labelFontSize = isMobile ? 20 : 18;
    final double inputFontSize = isMobile ? 20 : 13;
    final double buttonFontSize = isMobile ? 20 : 20;
    final double buttonHeight = isMobile ? 50 : 50;
    final double buttonWidth = isMobile ? 130 : 150;
    final double fieldSpacing = isMobile ? 15 : 25;
    final double sectionSpacing = isMobile ? 10 : 20;
    final double bottomSpacing = isMobile ? 40 : 80;

    final t = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: false,
            backgroundColor: Colors.black,
            title: Text(t.habitTitle,
                style: TextStyle(
                  fontSize: titleFontSize,
                  color: Colors.greenAccent,
                  fontFamily: 'Arial',
                ))),
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            color: Colors.black38,
            margin: EdgeInsets.all(horizontalMargin),
            padding: EdgeInsets.all(containerPadding),
            child: Column(
              children: [
                Text(
                  t.workDurationLabel,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                ),
                SizedBox(height: sectionSpacing),
                TextField(
                  controller: workController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: inputFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]?$')),
                  ],
                  decoration: InputDecoration(
                    fillColor: Colors.black12,
                    labelText: t.minutesHint,
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                  ),
                ),
                SizedBox(height: fieldSpacing),
                Text(
                  t.breakDurationLabel,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                ),
                SizedBox(height: sectionSpacing),
                TextField(
                  controller: breakController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: inputFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]?$')),
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black12,
                    labelText: t.minutesHint,
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                  ),
                ),
                SizedBox(height: fieldSpacing),
                Text(
                  t.sessionsLabel,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                ),
                SizedBox(height: sectionSpacing),
                TextField(
                  controller: sessionController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: inputFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]?$')),
                  ],
                  decoration: InputDecoration(
                    fillColor: Colors.black12,
                    labelText: t.sessionsHint,
                    labelStyle: const TextStyle(
                      color: Colors.white70,
                    ),
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                  ),
                ),
                SizedBox(height: fieldSpacing),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                SizedBox(height: fieldSpacing),
                Text(
                  t.dailyGoalLabel,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                ),
                SizedBox(height: sectionSpacing),
                TextField(
                  controller: goalController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: inputFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    fillColor: Colors.black12,
                    labelText: t.dailyGoalHint,
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                  ),
                  onChanged: (v) {
                    final m = int.tryParse(v);
                    if (m != null) repo.setDailyGoalMinutes(m);
                  },
                ),
                SizedBox(height: bottomSpacing),
                // Long break configuration
                Text(
                  t.longBreakConfigTitle,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                ),
                SizedBox(height: sectionSpacing),
                FutureBuilder(
                  future: Future.wait([
                    repo.getLongBreakInterval(),
                    repo.getLongBreakDurationMinutes(),
                  ]),
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox();
                    final interval = snap.data![0];
                    final duration = snap.data![1];
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.longBreakIntervalLabel,
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 12)),
                                  Slider(
                                    value: interval.toDouble(),
                                    min: 2,
                                    max: 8,
                                    divisions: 6,
                                    label: interval.toString(),
                                    onChanged: (v) async {
                                      await repo
                                          .setLongBreakInterval(v.round());
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.longBreakDurationLabel,
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 12)),
                                  Slider(
                                    value: duration.toDouble(),
                                    min: 5,
                                    max: 30,
                                    divisions: 5,
                                    label: duration.toString(),
                                    onChanged: (v) async {
                                      await repo.setLongBreakDurationMinutes(
                                          v.round());
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: fieldSpacing),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(seconds: 1),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return FadeTransition(
                            opacity: animation,
                            child: TimerScreen(
                                workMinutes:
                                    int.tryParse(workController.text) ?? 25,
                                breakMinutes:
                                    int.tryParse(breakController.text) ?? 5,
                                sessions:
                                    int.tryParse(sessionController.text) ?? 4));
                      },
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: EdgeInsets.zero,
                    minimumSize: Size(buttonWidth, buttonHeight),
                    fixedSize: Size(buttonWidth, buttonHeight),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.center,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.black12),
                    ),
                  ),
                  child: Hero(
                      tag: 'timerHero',
                      child: Text(
                        t.start,
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Arial',
                        ),
                      )),
                ),
              ],
            ),
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // withOpacity deprecated; using withValues
          color: Colors.greenAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent, width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
        ),
      ),
    );
  }
}
