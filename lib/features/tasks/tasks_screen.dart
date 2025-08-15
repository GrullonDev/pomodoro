import 'package:flutter/material.dart';
import 'package:pomodoro/core/data/task_repository.dart';
import 'package:pomodoro/core/timer/timer_screen.dart';

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
    await _repo.add(title);
    _controller.clear();
    await _load();
  }

  Future<void> _startFlow() async {
    await TaskFlowStarter.startFlow(context,
        tasks: _tasks,
        defaultWork: 25,
        defaultBreak: 5,
        defaultSessions: 4);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Tareas'),
        backgroundColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            labelText: 'Nueva tarea',
                          ),
                          onSubmitted: (_) => _add(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _add,
                        child: const Text('Agregar'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (ctx, i) {
                      final t = _tasks[i];
                      return ListTile(
                        leading: Icon(
                          t.done ? Icons.check_circle : Icons.circle_outlined,
                          color: t.done ? scheme.primary : null,
                        ),
                        title: Text(t.title,
                            style: TextStyle(
                                decoration: t.done
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none)),
                        subtitle: Text(t.done ? 'Completada' : 'Pendiente'),
                      );
                    },
                  ),
                ),
                if (_tasks.any((e) => !e.done))
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ElevatedButton.icon(
                      onPressed: _startFlow,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar enfoque'),
                    ),
                  ),
              ],
            ),
    );
  }
}
