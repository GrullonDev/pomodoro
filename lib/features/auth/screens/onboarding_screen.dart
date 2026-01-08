import 'package:flutter/material.dart';

import 'package:pomodoro/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSkip;
  const OnboardingScreen(
      {super.key, required this.onGetStarted, required this.onSkip});

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
          icon: Icons.timer,
        ),
        _OnbPage(
          title:
              t.localeName.startsWith('es') ? 'Cómo funciona' : 'How it works',
          body: t.localeName.startsWith('es')
              ? '25 minutos de enfoque + 5 minutos de descanso. Repite y cada 4 ciclos toma un descanso largo.'
              : '25 minutes focus + 5 minutes break. Repeat and every 4 cycles take a longer rest.',
          icon: Icons.loop,
        ),
        _OnbPage(
          title: t.localeName.startsWith('es')
              ? 'Beneficios clave'
              : 'Key benefits',
          body: t.localeName.startsWith('es')
              ? 'Reduce la fatiga mental, mejora la concentración y te ayuda a medir tu progreso diario con objetivos claros.'
              : 'Reduces mental fatigue, boosts focus, and lets you measure daily progress with clear goals.',
          icon: Icons.trending_up,
        ),
      ];

  void _nextOrFinish() {
    final pages = _pages(AppLocalizations.of(context));
    if (_index < pages.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(t.appTitle, style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: widget.onSkip,
            child: Text(t.localeName.startsWith('es') ? 'Saltar' : 'Skip',
                style: const TextStyle(color: Colors.black54)),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 26),
                        Icon(p.icon, size: 120, color: Colors.black87),
                        const SizedBox(height: 40),
                        Text(p.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87)),
                        const SizedBox(height: 16),
                        Text(p.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.black54)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  height: 8,
                  width: _index == i ? 32 : 10,
                  decoration: BoxDecoration(
                    color: _index == i ? Colors.black87 : Colors.black26,
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextOrFinish,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0A74E6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isLast
                        ? t.getStarted
                        : (t.localeName.startsWith('es')
                            ? 'Continuar'
                            : 'Continue'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnbPage {
  final String title;
  final String body;
  final IconData icon;
  _OnbPage({required this.title, required this.body, required this.icon});
}
