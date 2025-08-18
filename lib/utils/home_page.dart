import 'package:flutter/material.dart';

import 'package:pomodoro/features/habit/habit.dart';
import 'package:pomodoro/features/history/history_screen.dart';
import 'package:pomodoro/features/settings/settings_screen.dart';
import 'package:pomodoro/features/tasks/tasks_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
import 'package:pomodoro/core/auth/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  Widget _pageFor(int i) {
    switch (i) {
      case 0:
        return const Habit();
      case 1:
        return const TasksScreen();
      case 2:
        return const HistoryScreen();
      case 3:
      default:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(t.appTitle, style: const TextStyle(color: Colors.black87)),
        actions: [
          FutureBuilder<String?>(
            future: AuthService.instance.currentUid(),
            builder: (context, snap) {
              final uid = snap.data;
              return PopupMenuButton<int>(
                icon: const Icon(Icons.account_circle, color: Colors.black54),
                itemBuilder: (ctx) => [
                  PopupMenuItem<int>(value: 0, child: Text(uid ?? 'No account')),
                  const PopupMenuItem<int>(value: 1, child: Text('Sign out')),
                ],
                onSelected: (v) async {
                  if (v == 1) await AuthService.instance.signOut();
                },
              );
            },
          )
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pageFor(_index),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.15),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            selectedIcon: const Icon(Icons.timer),
            label: t.configure,
          ),
          const NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: t.history,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: t.settings,
          ),
        ],
      ),
    );
  }
}
