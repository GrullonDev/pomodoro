import 'package:flutter/material.dart';

import 'package:pomodoro/core/data/task_repository.dart';
import 'package:pomodoro/core/domain/entities/task.dart';
import 'package:pomodoro/core/timer/timer_screen.dart';
import 'package:pomodoro/features/focus_modes/focus_mode.dart';
import 'package:pomodoro/l10n/app_localizations.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _repo = TaskRepository();
  final _controller = TextEditingController();
  List<TaskItem> _tasks = [];
  bool _loading = true;
  FocusMode _selectedMode = FocusMode.sprint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.all();
    if (mounted) setState(() { _tasks = list; _loading = false; });
  }

  Future<void> _add() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    await _repo.add(title,
        work: _selectedMode.workMinutes,
        brk: _selectedMode.breakMinutes,
        sessions: _selectedMode.sessions);
    _controller.clear();
    await _load();
  }

  Future<void> _delete(String id) async {
    await _repo.delete(id);
    await _load();
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final tasks = List<TaskItem>.from(_tasks);
    final item = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, item);
    setState(() => _tasks = tasks);
    await _repo.saveAll(tasks);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final textColor = isDark ? const Color(0xFFEEEEF6) : const Color(0xFF1A1A2E);
    final subColor = isDark ? const Color(0xFF8A8AB0) : const Color(0xFF6B6B8A);
    final cardBg = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2E2E4A) : const Color(0xFFE0E0F0);
    final inputBg = isDark ? const Color(0xFF13131F) : const Color(0xFFF8F7FF);

    final done = _tasks.where((e) => e.done).length;
    final pending = _tasks.where((e) => !e.done).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary strip
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _StatChip(
                          value: pending.toString(),
                          label: 'Pendientes',
                          color: const Color(0xFFFFA552)),
                      const SizedBox(width: 10),
                      _StatChip(
                          value: done.toString(),
                          label: 'Completadas',
                          color: const Color(0xFF55EFC4)),
                      const SizedBox(width: 10),
                      _StatChip(
                          value: _tasks.length.toString(),
                          label: 'Total',
                          color: scheme.primary),
                    ],
                  ),
                ),

                // Add task input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: _controller,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Nueva tarea...',
                              hintStyle: TextStyle(
                                  color: subColor.withValues(alpha: 0.6)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                            ),
                            onSubmitted: (_) => _add(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _add,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Mode selector for new tasks
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text('Modo:',
                          style: TextStyle(fontSize: 12, color: subColor)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: FocusMode.all().map((m) {
                              final sel = m.id == _selectedMode.id;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedMode = m),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? m.color.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: sel ? m.color : borderColor),
                                  ),
                                  child: Text(
                                    '${m.emoji} ${m.name}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: sel ? m.color : subColor),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Task list
                Expanded(
                  child: _tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('✅',
                                  style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text('Sin tareas. ¡Agrega una!',
                                  style: TextStyle(
                                      color: subColor, fontSize: 15)),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          onReorder: _reorder,
                          itemCount: _tasks.length,
                          itemBuilder: (ctx, i) {
                            final t = _tasks[i];
                            return _TaskCard(
                              key: ValueKey(t.id),
                              task: t,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              textColor: textColor,
                              subColor: subColor,
                              onDelete: () => _delete(t.id),
                              onPlay: t.done
                                  ? null
                                  : () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TimerScreen(
                                            workMinutes: t.workMinutes,
                                            breakMinutes: t.breakMinutes,
                                            sessions: t.sessions,
                                            task: t,
                                            focusMode:
                                                FocusMode.fromId(t.id),
                                          ),
                                        ),
                                      );
                                      await _load();
                                    },
                            );
                          },
                        ),
                ),

                // Start all flow
                if (_tasks.any((e) => !e.done))
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await TaskFlowStarter.startFlow(
                            context,
                            tasks: _tasks,
                            defaultWork: _selectedMode.workMinutes,
                            defaultBreak: _selectedMode.breakMinutes,
                            defaultSessions: _selectedMode.sessions,
                          );
                          await _load();
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                            AppLocalizations.of(context).taskStartFlow),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatChip(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subColor;
  final VoidCallback onDelete;
  final VoidCallback? onPlay;

  const _TaskCard({
    super.key,
    required this.task,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subColor,
    required this.onDelete,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final modeColor = task.done
        ? const Color(0xFF55EFC4)
        : const Color(0xFF7C6FF7);
    final pct = task.sessions == 0
        ? 0.0
        : task.sessionsCompleted / task.sessions;

    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE17055).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFE17055), size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: task.done
                  ? const Color(0xFF55EFC4).withValues(alpha: 0.3)
                  : borderColor),
        ),
        child: Row(
          children: [
            // Progress circle
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 3,
                    backgroundColor: modeColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(modeColor),
                    strokeCap: StrokeCap.round,
                  ),
                  if (task.done)
                    Icon(Icons.check_rounded,
                        size: 16, color: modeColor)
                  else
                    Text(
                      '${task.sessionsCompleted}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: modeColor),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: task.done
                          ? subColor
                          : textColor,
                      decoration: task.done
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${task.sessionsCompleted}/${task.sessions} sesiones · ${task.workMinutes}min',
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                ],
              ),
            ),
            // Play button
            if (onPlay != null)
              GestureDetector(
                onTap: onPlay,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: modeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.play_arrow_rounded,
                      size: 20, color: modeColor),
                ),
              )
            else
              Icon(Icons.drag_handle_rounded, size: 20, color: subColor),
          ],
        ),
      ),
    );
  }
}
