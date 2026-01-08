import 'package:flutter/material.dart';

import 'package:pomodoro/core/auth/auth_service.dart';
import 'package:pomodoro/features/auth/login_screen.dart';
import 'package:pomodoro/features/auth/screens/profile_screen.dart';
import 'package:pomodoro/features/habit/habit.dart';
import 'package:pomodoro/features/history/history_screen.dart';
import 'package:pomodoro/features/settings/settings_screen.dart';
import 'package:pomodoro/features/tasks/tasks_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
import 'package:pomodoro/utils/app.dart';
import 'package:pomodoro/features/gamification/gamification_service.dart';

import 'package:pomodoro/features/gamification/presentation/screens/achievements_screen.dart';

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
        // Remove hardcoded backgroundColor so it uses the theme (transparent)
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(t.appTitle),
        actions: [
          // Level Indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ValueListenableBuilder<int>(
              valueListenable: GamificationService.instance.currentLevel,
              builder: (context, level, _) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AchievementsScreen()));
                  },
                  child: Chip(
                    avatar:
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                    label: Text('Lvl $level',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface)),
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.2),
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),
          FutureBuilder<Map<String, String?>>(
            future: AuthService.instance.currentProfile(),
            builder: (context, snap) {
              final profile = snap.data;
              final name = profile?['name'];
              final uid = profile?['uid'];
              final t = AppLocalizations.of(context);
              return PopupMenuButton<int>(
                icon: const Icon(Icons.account_circle),
                itemBuilder: (ctx) => [
                  PopupMenuItem<int>(
                    value: 0,
                    child: Text(
                      name?.isNotEmpty == true ? name! : t.profileMenu,
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 2,
                    child: Text(
                      uid ?? t.idUnavailable,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 1,
                    child: Text(t.signOut),
                  ),
                ],
                onSelected: (v) async {
                  if (v == 0) {
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  } else if (v == 1) {
                    await AuthService.instance.signOut();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) =>
                            const AnimatedGradientShell(child: LoginScreen()),
                      ),
                      (route) => false,
                    );
                  }
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
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: t.tasksTitle,
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
