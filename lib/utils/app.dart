import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/theme/locale_controller.dart';
import 'package:pomodoro/core/theme/theme_controller.dart';
import 'package:pomodoro/features/auth/screens/onboarding_screen.dart';
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
      const bg = Color(0xFF0B0B14);
      const surface = Color(0xFF13131F);
      const card = Color(0xFF1C1C2E);
      const primary = Color(0xFF7C6FF7);
      const onPrimary = Colors.white;
      const textPrimary = Color(0xFFEEEEF6);
      const textSecondary = Color(0xFF8A8AB0);

      final scheme = ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        secondary: const Color(0xFF4ECDC4),
        onSecondary: Colors.black,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: card,
        outline: const Color(0xFF2E2E4A),
        error: const Color(0xFFE17055),
      );

      return ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: scheme,
        scaffoldBackgroundColor: bg,
        cardColor: card,
        dividerColor: const Color(0xFF2E2E4A),
        textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: textPrimary,
              displayColor: textPrimary,
            ).copyWith(
              bodySmall: const TextStyle(color: textSecondary),
              labelSmall: const TextStyle(color: textSecondary),
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: primary.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, color: textSecondary),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: onPrimary,
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E2E4A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E2E4A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: Color(0xFF4A4A6A)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: card,
          selectedColor: primary.withValues(alpha: 0.2),
          side: const BorderSide(color: Color(0xFF2E2E4A)),
          labelStyle: const TextStyle(color: textPrimary),
        ),
      );
    }

    ThemeData buildLight() {
      const bg = Color(0xFFF5F4FF);
      const surface = Color(0xFFFFFFFF);
      const card = Color(0xFFFFFFFF);
      const primary = Color(0xFF7C6FF7);
      const onPrimary = Colors.white;
      const textPrimary = Color(0xFF1A1A2E);
      const textSecondary = Color(0xFF6B6B8A);

      final scheme = ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        secondary: const Color(0xFF4ECDC4),
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: card,
        outline: const Color(0xFFE0E0F0),
        error: const Color(0xFFE17055),
      );

      return ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: scheme,
        scaffoldBackgroundColor: bg,
        cardColor: card,
        dividerColor: const Color(0xFFE0E0F0),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: textPrimary,
              displayColor: textPrimary,
            ).copyWith(
              bodySmall: const TextStyle(color: textSecondary),
              labelSmall: const TextStyle(color: textSecondary),
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: primary.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, color: textSecondary),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: onPrimary,
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF0EFF9),
          selectedColor: primary.withValues(alpha: 0.15),
          side: const BorderSide(color: Color(0xFFE0E0F0)),
          labelStyle: const TextStyle(color: textPrimary),
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
            home: UpgradeAlert(
              showIgnore: false,
              showLater: false,
              showReleaseNotes: true,
              dialogStyle: UpgradeDialogStyle.cupertino,
              upgrader: Upgrader(
                messages: UpgraderMessages(code: 'es'),
              ),
              child: FutureBuilder<bool>(
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
                          // Sign in anonymously (guest mode) — stream will
                          // rebuild to HomePage automatically.
                          await AuthService.instance.signInAnonymously();
                        },
                        onSkip: () async {
                          await SessionRepository().setOnboardingSeen();
                          await AuthService.instance.signInAnonymously();
                        },
                      ),
                    );
                  }

                  // If onboarding completed, auto-sign in as guest and show
                  // the dashboard.  LoginScreen is accessed only when the user
                  // explicitly wants to save / sync their progress.
                  return StreamBuilder<String?>(
                    stream: AuthService.instance.uidChanges(),
                    builder: (context, authSnap) {
                      final uid = authSnap.data;

                      // No active session → sign in anonymously (guest mode).
                      if (uid == null) {
                        AuthService.instance.signInAnonymously();
                        return const AnimatedGradientShell(
                          child: _LoadingScreen(),
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
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
        ..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0B14) : const Color(0xFFF5F4FF);
    // Subtle accent glow color
    const glowColor = Color(0xFF7C6FF7);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(color: bg),
            // Subtle top-right glow that gently breathes
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.9, -0.8),
                    radius: 1.2,
                    colors: [
                      glowColor.withValues(alpha: 0.06 + (_c.value * 0.04)),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
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

/// Shown briefly while anonymous sign-in is in progress.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7C6FF7),
          strokeWidth: 2,
        ),
      ),
    );
  }
}
