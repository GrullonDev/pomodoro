// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Pomodoro Enfoque';

  @override
  String get timerReady => 'Listo';

  @override
  String workPhase(Object current, Object total) {
    return 'Trabajo $current/$total';
  }

  @override
  String get breakPhase => 'Descanso';

  @override
  String get pause => 'Pausar';

  @override
  String get resume => 'Reanudar';

  @override
  String get skip => 'Saltar';

  @override
  String get start => 'Iniciar';

  @override
  String get newSession => 'Nueva Sesión';

  @override
  String get share => 'Compartir';

  @override
  String get sessionCompleted => '¡Sesión completada!';

  @override
  String get todayProgress => 'Progreso de Hoy';

  @override
  String get last7Days => 'Últimos 7 días';

  @override
  String dailyGoal(Object minutes) {
    return 'Meta diaria: $minutes min';
  }

  @override
  String longBreakEvery(Object count) {
    return 'Descanso largo cada $count sesiones';
  }

  @override
  String get longBreak => 'Descanso largo';

  @override
  String get settings => 'Configuración';

  @override
  String minutesShort(Object minutes) {
    return '${minutes}m';
  }

  @override
  String get dailyGoalReached => 'Meta diaria alcanzada';

  @override
  String get goalReachedBody => 'Excelente! Llegaste a tu objetivo.';

  @override
  String get phaseEndedBody => 'La fase ha terminado, toca para continuar';

  @override
  String get phaseWorkTitle => 'Fase de trabajo';

  @override
  String get phaseBreakTitle => 'Fase de descanso';

  @override
  String get shareImage => 'Compartir Imagen';

  @override
  String get generatingImage => 'Generando imagen...';

  @override
  String get longBreakIntervalLabel => 'Descanso largo cada (sesiones)';

  @override
  String get longBreakDurationLabel => 'Minutos de descanso largo';

  @override
  String get configuredLongBreak => 'Descanso largo configurado';

  @override
  String get advancedChartTitle => 'Enfoque últimos 7 días';

  @override
  String get avgLabel => 'Prom';

  @override
  String get pauseAction => 'Pausar';

  @override
  String get resumeAction => 'Reanudar';

  @override
  String get skipAction => 'Saltar';

  @override
  String get focusPersistentTitle => 'Modo Focus';

  @override
  String get focusPersistentBody => 'Toca acciones para controlar';

  @override
  String get history => 'Historial';

  @override
  String get configure => 'Configurar';

  @override
  String get noHistory => 'Sin historial aún';

  @override
  String get habitTitle => 'Iniciar Pomodoro';

  @override
  String get workDurationLabel => 'Duración de trabajo';

  @override
  String get breakDurationLabel => 'Duración de descanso';

  @override
  String get sessionsLabel => 'Sesiones';

  @override
  String get minutesHint => '(En minutos)';

  @override
  String get sessionsHint => '(Número de sesiones)';

  @override
  String get dailyGoalLabel => 'Meta diaria (min)';

  @override
  String get dailyGoalHint => '(Ej: 120)';

  @override
  String get longBreakConfigTitle => 'Descanso largo (config)';

  @override
  String get presetFast => 'Rápido 15/3 x4';

  @override
  String get presetClassic => 'Clásico 25/5 x4';

  @override
  String get presetDeep => 'Profundo 50/10 x3';

  @override
  String get settingsPersistentNotif => 'Notificación persistente';

  @override
  String get settingsPersistentNotifDesc => 'Mostrar controles en notificación';

  @override
  String get dayDetailTitle => 'Día de enfoque';

  @override
  String get totalFocus => 'Enfoque total';

  @override
  String sessionsCount(Object count) {
    return '$count sesiones';
  }

  @override
  String get noSessionsDay => 'Sin sesiones este día';

  @override
  String get last5AlertTitle => 'Alerta últimos 5s';

  @override
  String get last5AlertDesc => 'Sonido y flash durante los últimos 5 segundos';

  @override
  String dailyGoalRemaining(Object minutes) {
    return 'Restante para meta: ${minutes}m';
  }

  @override
  String get last5SoundTitle => 'Reproducir sonido (últimos 5s)';

  @override
  String get last5SoundDesc => 'Aviso audible en los últimos 5 segundos';

  @override
  String goalProgressLabel(Object done, Object total) {
    return 'Progreso meta: ${done}m / ${total}m';
  }

  @override
  String get last5FlashTitle => 'Parpadear pantalla (últimos 5s)';

  @override
  String get last5FlashDesc => 'Flash visual durante los últimos 5 segundos';

  @override
  String get tasksTitle => 'Tareas';

  @override
  String get taskNewLabel => 'Nueva tarea';

  @override
  String get taskAdd => 'Agregar';

  @override
  String get taskWorkLabel => 'Trabajo';

  @override
  String get taskBreakLabel => 'Descanso';

  @override
  String get taskSessionsShort => 'Ses';

  @override
  String get taskStartFlow => 'Iniciar flujo';

  @override
  String taskProgressSummary(Object done, Object pending, Object total) {
    return 'Tareas: $done/$total • $pending pendientes';
  }

  @override
  String taskSessionProgress(Object completed, Object total) {
    return '$completed/$total sesiones';
  }

  @override
  String get languageSetting => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSyncPreset => 'Sincronizar preset';

  @override
  String get onboardingTitle => 'Mantén el enfoque, logra más';

  @override
  String get onboardingSubtitle =>
      'Usa foco estructurado y descansos para alcanzar tus metas más rápido.';

  @override
  String get getStarted => 'Comenzar';
}
