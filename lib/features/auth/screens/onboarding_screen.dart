import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pomodoro/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSkip;
  const OnboardingScreen({
    super.key,
    required this.onGetStarted,
    required this.onSkip,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  List<_OnbPage> _pages(AppLocalizations t) => [
        _OnbPage(
          title: t.onboardingTitle,
          body: t.onboardingSubtitle,
          asset: 'assets/onboarding/focus.png',
          color: const Color(0xFFFF5F5F),
        ),
        _OnbPage(
          title:
              t.localeName.startsWith('es') ? 'Estado de Flow' : 'Flow State',
          body: t.localeName.startsWith('es')
              ? '25 minutos de enfoque real + 5 minutos de descanso. Recupera tu energía de forma estructurada.'
              : '25 minutes of deep focus + 5 minutes break. Recharge your energy predictably.',
          asset: 'assets/onboarding/flow.png',
          color: const Color(0xFF4AC3FF),
        ),
        _OnbPage(
          title: t.localeName.startsWith('es')
              ? 'Logra tus Metas'
              : 'Achieve Your Goals',
          body: t.localeName.startsWith('es')
              ? 'Mide tu progreso y alcanza tus objetivos diarios con un sistema diseñado para el éxito.'
              : 'Track your progress and hit your daily targets with a system designed for success.',
          asset: 'assets/onboarding/success.png',
          color: const Color(0xFFFFD541),
        ),
      ];

  void _nextOrFinish() {
    final pages = _pages(AppLocalizations.of(context));
    if (_index < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      widget.onGetStarted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pages = _pages(t);
    final isLast = _index == pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: Stack(
        children: [
          // Dynamic Background Glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.8, -0.5),
                radius: 1.5,
                colors: [
                  pages[_index].color.withValues(alpha: 0.15),
                  const Color(0xFF0F1115),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.appTitle.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onSkip,
                        child: Text(
                          t.localeName.startsWith('es') ? 'SALTAR' : 'SKIP',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final p = pages[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 800),
                                scale: _index == i ? 1.0 : 0.8,
                                curve: Curves.elasticOut,
                                child: Image.asset(
                                  p.asset,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, _, __) => Container(
                                    decoration: BoxDecoration(
                                      color: p.color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Icon(Icons.image,
                                        size: 100,
                                        color: p.color.withValues(alpha: 0.3)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),
                            Text(
                              p.title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              p.body,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Footer section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: _index == i ? 24 : 6,
                            decoration: BoxDecoration(
                              color: _index == i
                                  ? pages[_index].color
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: FilledButton(
                          onPressed: _nextOrFinish,
                          style: FilledButton.styleFrom(
                            backgroundColor: pages[_index].color,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            isLast
                                ? t.getStarted.toUpperCase()
                                : (t.localeName.startsWith('es')
                                    ? 'CONTINUAR'
                                    : 'CONTINUE'),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnbPage {
  final String title;
  final String body;
  final String asset;
  final Color color;
  _OnbPage({
    required this.title,
    required this.body,
    required this.asset,
    required this.color,
  });
}
