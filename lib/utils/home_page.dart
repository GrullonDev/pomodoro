import 'package:flutter/material.dart';

import 'package:pomodoro/features/habit/habit.dart';
import 'package:pomodoro/features/history/history_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
import 'package:pomodoro/features/settings/settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  Widget _pageFor(int i) {
    switch (i) {
      case 1:
        return const HistoryScreen();
      case 2:
        return const SettingsScreen();
      case 0:
      default:
        return const Habit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pageFor(_index),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.black,
        indicatorColor: Colors.greenAccent.withValues(alpha: 0.15),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            selectedIcon: const Icon(Icons.timer),
            label: t.configure,
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
