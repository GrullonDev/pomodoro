import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pomodoro/l10n/app_localizations.dart';

import 'package:pomodoro/utils/home_page.dart';
import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/features/auth/screens/onboarding_screen.dart';
import 'package:pomodoro/core/theme/theme_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    ThemeData buildDark() {
      final base = ThemeData.dark(useMaterial3: true);
      final scheme = base.colorScheme.copyWith(
        primary: Colors.greenAccent.shade400,
        secondary: Colors.greenAccent.shade400,
      );
      return base.copyWith(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0D0F11),
        textTheme: base.textTheme.apply(fontFamily: 'Arial'),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent, elevation: 0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    ThemeData buildLight() {
      final base = ThemeData.light(useMaterial3: true);
      final scheme = base.colorScheme.copyWith(
        primary: const Color(0xFF00B86B),
        secondary: const Color(0xFF00B86B),
      );
      return base.copyWith(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF8F6FB),
        textTheme: base.textTheme.apply(fontFamily: 'Arial'),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent, elevation: 0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDark,
      builder: (_, isDark, __) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: isDark ? buildDark() : buildLight(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('es')],
          home: FutureBuilder<bool>(
            future: SessionRepository().isOnboardingSeen(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final seen = snap.data ?? false;
              if (seen) {
                return const AnimatedGradientShell(child: HomePage());
              }
              return AnimatedGradientShell(
                child: OnboardingScreen(
                  onGetStarted: () async {
                    await SessionRepository().setOnboardingSeen();
                    if (navigatorKey.currentState?.mounted ?? false) {
                      navigatorKey.currentState!.pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const AnimatedGradientShell(
                                  child: HomePage(),
                                )),
                      );
                    }
                  },
                  onSkip: () async {
                    await SessionRepository().setOnboardingSeen();
                    if (navigatorKey.currentState?.mounted ?? false) {
                      navigatorKey.currentState!.pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const AnimatedGradientShell(
                                  child: HomePage(),
                                )),
                      );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class AnimatedGradientShell extends StatefulWidget {
  final Widget child;
  const AnimatedGradientShell({super.key, required this.child});
  @override
  State<AnimatedGradientShell> createState() => _AnimatedGradientShellState();
}

class _AnimatedGradientShellState extends State<AnimatedGradientShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))
        ..repeat(reverse: true);
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final colors = isDark
            ? [
                const Color(0xFF0F2027),
                const Color(0xFF203A43),
                const Color(0xFF2C5364),
              ]
            : [
                const Color(0xFFE9FDF5),
                const Color(0xFFE3F5FF),
                const Color(0xFFF0F3FF),
              ];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(colors[0], colors[1], _c.value * .8)!,
                Color.lerp(colors[1], colors[2], _c.value)!,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}
