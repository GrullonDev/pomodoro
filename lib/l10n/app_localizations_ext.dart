// Temporary extension providing onboarding/auth strings outside generated localization.
// TODO: Move these keys into ARB files (app_en.arb, app_es.arb) and regenerate with flutter gen-l10n.
import 'app_localizations.dart';

extension AppLocalizationsAuth on AppLocalizations {
  String get onboardingTitle => localeName.startsWith('es')
      ? 'Mantén el enfoque, logra más'
      : 'Stay focused, achieve more';
  String get onboardingSubtitle => localeName.startsWith('es')
      ? 'Usa foco estructurado y descansos para alcanzar tus metas más rápido.'
      : 'Use structured focus & breaks to reach your goals faster.';
  String get getStarted =>
      localeName.startsWith('es') ? 'Comenzar' : 'Get started';
}
