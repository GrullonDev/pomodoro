import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pomodoro/l10n/app_localizations.dart';

import 'package:pomodoro/utils/landing.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    final theme = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: Colors.greenAccent,
        secondary: Colors.greenAccent,
      ),
      scaffoldBackgroundColor: Colors.black,
      textTheme: base.textTheme.apply(
          fontFamily: 'Arial',
          bodyColor: Colors.greenAccent,
          displayColor: Colors.greenAccent),
      appBarTheme:
          const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: theme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      home: const AnimatedGradientShell(child: LandingPage()),
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
        final colors = [
          const Color(0xFF0F2027),
          const Color(0xFF203A43),
          const Color(0xFF2C5364),
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
