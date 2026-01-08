import 'package:flutter/material.dart';
import 'package:pomodoro/features/gamification/data/badges_repository.dart';
import 'package:pomodoro/features/gamification/domain/game_badge.dart';
import 'package:pomodoro/utils/glass_container.dart';
import 'package:pomodoro/utils/app.dart'; // for AnimatedGradientShell if simpler wrapping needed, but usually passed from parent or Main

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _repo = BadgesRepository();
  Map<String, bool> _status = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.getBadgesStatus();
    if (mounted) {
      setState(() {
        _status = s;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we want the gradient, we can wrap in AnimatedGradientShell or assume it's pushed on top of one.
    // However, pushing a MaterialPageRoute usually covers the previous stack.
    // Let's wrap it in AnimatedGradientShell to be safe and consistent.
    return AnimatedGradientShell(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Logros',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold)),
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: BadgesRepository.allBadges.length,
                itemBuilder: (ctx, i) {
                  final badge = BadgesRepository.allBadges[i];
                  final unlocked = _status[badge.id] ?? false;
                  return _BadgeCard(badge: badge, unlocked: unlocked);
                },
              ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final GameBadge badge;
  final bool unlocked;

  const _BadgeCard({required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contentColor = unlocked
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.3);

    return GlassContainer(
      borderRadius: 20,
      color: unlocked
          ? colorScheme.primary
              .withValues(alpha: 0.1) // Subtle tint for unlocked
          : colorScheme.surface
              .withValues(alpha: 0.05), // Very dark/faint for locked
      border: Border.all(
          color: unlocked
              ? colorScheme.primary.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked
                    ? Colors.amber.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
                boxShadow: unlocked
                    ? [
                        BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2)
                      ]
                    : [],
              ),
              child: Icon(
                badge.icon,
                size: 40,
                color: unlocked
                    ? Colors.amber
                    : Colors.grey.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: contentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: contentColor.withValues(alpha: 0.7),
              ),
            ),
            if (!unlocked)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Icon(Icons.lock_outline,
                    size: 16, color: contentColor.withValues(alpha: 0.5)),
              )
          ],
        ),
      ),
    );
  }
}
