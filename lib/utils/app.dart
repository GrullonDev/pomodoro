import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/theme/locale_controller.dart';
import 'package:pomodoro/core/theme/theme_controller.dart';
import 'package:pomodoro/features/auth/screens/onboarding_screen.dart';
import 'package:pomodoro/features/auth/login_screen.dart';
import 'package:pomodoro/core/auth/auth_service.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
import 'package:pomodoro/utils/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    // Cargar locale guardado (solo se dispara una vez; si ya está cargado no hace nada)
    LocaleController.instance.load();
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
        return ValueListenableBuilder<Locale?>(
          valueListenable: LocaleController.instance.locale,
          builder: (_, loc, ___) => MaterialApp(
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
            locale: loc,
            home: FutureBuilder<bool>(
              future: SessionRepository().isOnboardingSeen(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final seen = snap.data ?? false;
                if (!seen) {
                  return AnimatedGradientShell(
                    child: OnboardingScreen(
                      onGetStarted: () async {
                        await SessionRepository().setOnboardingSeen();
                        if (navigatorKey.currentState?.mounted ?? false) {
                          navigatorKey.currentState!.pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => AnimatedGradientShell(
                                child: LoginScreen(),
                              ),
                            ),
                          );
                        }
                      },
                      onSkip: () async {
                        await SessionRepository().setOnboardingSeen();
                        if (navigatorKey.currentState?.mounted ?? false) {
                          navigatorKey.currentState!.pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => AnimatedGradientShell(
                                child: LoginScreen(),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                }

                // If onboarding completed, show Home or Login depending on auth state.
                return StreamBuilder<String?>(
                  stream: AuthService.instance.uidChanges(),
                  builder: (context, authSnap) {
                    final uid = authSnap.data;
                    if (authSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (uid == null) {
                      return const AnimatedGradientShell(
                        child: LoginScreen(),
                      );
                    }

                    return const AnimatedGradientShell(
                      child: HomePage(),
                    );
                  },
                );
              },
            ),
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
        // We use a rich dark gradient by default to make the glassmorphism pop,
        // regardless of the system light/dark mode for this shell.

        // Deep teal/ocean palette
        const c1 = Color(0xFF0F2027);
        const c2 = Color(0xFF203A43);
        const c3 = Color(0xFF2C5364);

        // Secondary accent palette (Emerald) for animation
        const a1 = Color(0xFF134E5E);
        const a2 = Color(0xFF71B280);

        final animT = _c.value;

        // Animate between the deep palette and a slightly more vibrant one
        final g1 = Color.lerp(c1, a1, animT * 0.5)!;
        final g2 = Color.lerp(c2, c1, animT * 0.3)!;
        final g3 = Color.lerp(c3, a2, animT * 0.4)!;

        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [g1, g2, g3],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Radial accent glow (animated subtle pulse)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, -0.6),
                    radius: 1.5,
                    colors: [
                      Colors.greenAccent.withOpacity(0.1 + (animT * 0.05)),
                      Colors.transparent,
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
            ),
            // Content
            widget.child,
          ],
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
