import 'package:flutter/material.dart';

import 'package:pomodoro/core/auth/auth_service.dart';
import 'package:pomodoro/features/auth/login_screen.dart';
import 'package:pomodoro/features/auth/screens/profile_screen.dart';
import 'package:pomodoro/features/flow_home/flow_home_screen.dart';
import 'package:pomodoro/features/settings/settings_screen.dart';
import 'package:pomodoro/features/tasks/tasks_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
import 'package:pomodoro/utils/app.dart';
import 'package:pomodoro/features/gamification/gamification_service.dart';
import 'package:pomodoro/features/gamification/presentation/screens/achievements_screen.dart';
import 'package:pomodoro/features/audio/presentation/audio_mixer_sheet.dart';
import 'package:pomodoro/features/analytics/presentation/screens/analytics_screen.dart';

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
        return const FlowHomeScreen();
      case 1:
        return const TasksScreen();
      case 2:
        return const AnalyticsScreen();
      case 3:
      default:
        return const SettingsScreen();
    }
  }

  static const _tabTitles = ['Inicio', 'Tareas', 'Métricas', 'Ajustes'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final textColor = isDark ? const Color(0xFFEEEEF6) : const Color(0xFF1A1A2E);
    final subColor = isDark ? const Color(0xFF8A8AB0) : const Color(0xFF6B6B8A);
    final surfaceBg = isDark ? const Color(0xFF13131F) : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _tabTitles[_index],
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        actions: [
          // Ambient audio
          IconButton(
            icon: Icon(Icons.waves_rounded, size: 22, color: subColor),
            tooltip: 'Sonidos ambientales',
            onPressed: () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => const AudioMixerSheet(),
            ),
          ),
          // Level chip
          ValueListenableBuilder<int>(
            valueListenable: GamificationService.instance.currentLevel,
            builder: (_, level, __) => GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AchievementsScreen())),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C6FF7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF7C6FF7).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✦',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF7C6FF7))),
                    const SizedBox(width: 4),
                    Text(
                      'Nv $level',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7C6FF7)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Profile
          FutureBuilder<Map<String, String?>>(
            future: AuthService.instance.currentProfile(),
            builder: (context, snap) {
              final profile = snap.data;
              final name = profile?['name'];
              return PopupMenuButton<int>(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      const Color(0xFF7C6FF7).withValues(alpha: 0.15),
                  child: Text(
                    name?.isNotEmpty == true
                        ? name!.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C6FF7)),
                  ),
                ),
                itemBuilder: (_) => [
                  PopupMenuItem<int>(
                    value: 0,
                    child: Row(children: [
                      const Icon(Icons.person_outline_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(name?.isNotEmpty == true ? name! : 'Perfil'),
                    ]),
                  ),
                  PopupMenuItem<int>(
                    value: 1,
                    child: Row(children: [
                      const Icon(Icons.logout_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(AppLocalizations.of(context).signOut),
                    ]),
                  ),
                ],
                onSelected: (v) async {
                  if (v == 0) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  } else if (v == 1) {
                    await AuthService.instance.signOut();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AnimatedGradientShell(child: LoginScreen())),
                      (r) => false,
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _pageFor(_index),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceBg,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF2E2E4A)
                  : const Color(0xFFE0E0F0),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: scheme.primary.withValues(alpha: 0.15),
          onDestinationSelected: (i) => setState(() => _index = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: subColor),
              selectedIcon:
                  Icon(Icons.home_rounded, color: scheme.primary),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.check_box_outlined, color: subColor),
              selectedIcon:
                  Icon(Icons.check_box_rounded, color: scheme.primary),
              label: 'Tareas',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: subColor),
              selectedIcon:
                  Icon(Icons.bar_chart_rounded, color: scheme.primary),
              label: 'Métricas',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined, color: subColor),
              selectedIcon: Icon(Icons.tune_rounded, color: scheme.primary),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
