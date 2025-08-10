// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pomodoro Focus';

  @override
  String get timerReady => 'Ready';

  @override
  String workPhase(Object current, Object total) {
    return 'Work $current/$total';
  }

  @override
  String get breakPhase => 'Break';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get skip => 'Skip';

  @override
  String get start => 'Start';

  @override
  String get newSession => 'New Session';

  @override
  String get share => 'Share';

  @override
  String get sessionCompleted => 'Session Completed!';

  @override
  String get todayProgress => 'Today\'s Progress';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String dailyGoal(Object minutes) {
    return 'Daily goal: $minutes min';
  }

  @override
  String longBreakEvery(Object count) {
    return 'Long break every $count sessions';
  }

  @override
  String get longBreak => 'Long break';

  @override
  String get settings => 'Settings';

  @override
  String minutesShort(Object minutes) {
    return '${minutes}m';
  }

  @override
  String get dailyGoalReached => 'Daily goal reached';

  @override
  String get goalReachedBody => 'Great! You hit your focus goal.';

  @override
  String get phaseEndedBody => 'Phase ended, tap to continue';

  @override
  String get phaseWorkTitle => 'Work phase';

  @override
  String get phaseBreakTitle => 'Break phase';

  @override
  String get shareImage => 'Share Image';

  @override
  String get generatingImage => 'Generating image...';

  @override
  String get longBreakIntervalLabel => 'Long break every (sessions)';

  @override
  String get longBreakDurationLabel => 'Long break minutes';

  @override
  String get configuredLongBreak => 'Configured long break';

  @override
  String get advancedChartTitle => 'Focus last 7 days';

  @override
  String get avgLabel => 'Avg';

  @override
  String get pauseAction => 'Pause';

  @override
  String get resumeAction => 'Resume';

  @override
  String get skipAction => 'Skip';

  @override
  String get focusPersistentTitle => 'Focus Mode';

  @override
  String get focusPersistentBody => 'Tap actions to control timer';

  @override
  String get history => 'History';

  @override
  String get configure => 'Configure';

  @override
  String get noHistory => 'No focus history yet';

  @override
  String get habitTitle => 'Start Pomodoro';

  @override
  String get workDurationLabel => 'Work duration';

  @override
  String get breakDurationLabel => 'Break duration';

  @override
  String get sessionsLabel => 'Sessions';

  @override
  String get minutesHint => '(In minutes)';

  @override
  String get sessionsHint => '(Number of sessions)';

  @override
  String get dailyGoalLabel => 'Daily goal (min)';

  @override
  String get dailyGoalHint => '(Eg: 120)';

  @override
  String get longBreakConfigTitle => 'Long break (config)';

  @override
  String get presetFast => 'Fast 15/3 x4';

  @override
  String get presetClassic => 'Classic 25/5 x4';

  @override
  String get presetDeep => 'Deep 50/10 x3';

  @override
  String get settingsPersistentNotif => 'Persistent notification';

  @override
  String get settingsPersistentNotifDesc =>
      'Show ongoing notification controls';

  @override
  String get dayDetailTitle => 'Focus day';

  @override
  String get totalFocus => 'Total focus';

  @override
  String sessionsCount(Object count) {
    return '$count sessions';
  }

  @override
  String get noSessionsDay => 'No sessions this day';

  @override
  String get last5AlertTitle => 'Final 5s alert';

  @override
  String get last5AlertDesc => 'Sound & flash during last 5 seconds';

  @override
  String dailyGoalRemaining(Object minutes) {
    return 'Remaining to goal: ${minutes}m';
  }

  @override
  String get last5SoundTitle => 'Play sound (last 5s)';

  @override
  String get last5SoundDesc => 'Audible cue in the final 5 seconds';

  @override
  String goalProgressLabel(Object done, Object total) {
    return 'Goal progress: ${done}m / ${total}m';
  }

  @override
  String get last5FlashTitle => 'Flash screen (last 5s)';

  @override
  String get last5FlashDesc => 'Visual flash during final 5 seconds';
}
