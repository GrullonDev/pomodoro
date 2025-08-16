import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Focus'**
  String get appTitle;

  /// No description provided for @timerReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get timerReady;

  /// No description provided for @workPhase.
  ///
  /// In en, this message translates to:
  /// **'Work {current}/{total}'**
  String workPhase(Object current, Object total);

  /// No description provided for @breakPhase.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get breakPhase;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @newSession.
  ///
  /// In en, this message translates to:
  /// **'New Session'**
  String get newSession;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @sessionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Session Completed!'**
  String get sessionCompleted;

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todayProgress;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal: {minutes} min'**
  String dailyGoal(Object minutes);

  /// No description provided for @longBreakEvery.
  ///
  /// In en, this message translates to:
  /// **'Long break every {count} sessions'**
  String longBreakEvery(Object count);

  /// No description provided for @longBreak.
  ///
  /// In en, this message translates to:
  /// **'Long break'**
  String get longBreak;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String minutesShort(Object minutes);

  /// No description provided for @dailyGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Daily goal reached'**
  String get dailyGoalReached;

  /// No description provided for @goalReachedBody.
  ///
  /// In en, this message translates to:
  /// **'Great! You hit your focus goal.'**
  String get goalReachedBody;

  /// No description provided for @phaseEndedBody.
  ///
  /// In en, this message translates to:
  /// **'Phase ended, tap to continue'**
  String get phaseEndedBody;

  /// No description provided for @phaseWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Work phase'**
  String get phaseWorkTitle;

  /// No description provided for @phaseBreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Break phase'**
  String get phaseBreakTitle;

  /// No description provided for @shareImage.
  ///
  /// In en, this message translates to:
  /// **'Share Image'**
  String get shareImage;

  /// No description provided for @generatingImage.
  ///
  /// In en, this message translates to:
  /// **'Generating image...'**
  String get generatingImage;

  /// No description provided for @longBreakIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Long break every (sessions)'**
  String get longBreakIntervalLabel;

  /// No description provided for @longBreakDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Long break minutes'**
  String get longBreakDurationLabel;

  /// No description provided for @configuredLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Configured long break'**
  String get configuredLongBreak;

  /// No description provided for @advancedChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus last 7 days'**
  String get advancedChartTitle;

  /// No description provided for @avgLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avgLabel;

  /// No description provided for @pauseAction.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseAction;

  /// No description provided for @resumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeAction;

  /// No description provided for @skipAction.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipAction;

  /// No description provided for @focusPersistentTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode'**
  String get focusPersistentTitle;

  /// No description provided for @focusPersistentBody.
  ///
  /// In en, this message translates to:
  /// **'Tap actions to control timer'**
  String get focusPersistentBody;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @configure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configure;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No focus history yet'**
  String get noHistory;

  /// No description provided for @habitTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Pomodoro'**
  String get habitTitle;

  /// No description provided for @workDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Work duration'**
  String get workDurationLabel;

  /// No description provided for @breakDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Break duration'**
  String get breakDurationLabel;

  /// No description provided for @sessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionsLabel;

  /// No description provided for @minutesHint.
  ///
  /// In en, this message translates to:
  /// **'(In minutes)'**
  String get minutesHint;

  /// No description provided for @sessionsHint.
  ///
  /// In en, this message translates to:
  /// **'(Number of sessions)'**
  String get sessionsHint;

  /// No description provided for @dailyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily goal (min)'**
  String get dailyGoalLabel;

  /// No description provided for @dailyGoalHint.
  ///
  /// In en, this message translates to:
  /// **'(Eg: 120)'**
  String get dailyGoalHint;

  /// No description provided for @longBreakConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Long break (config)'**
  String get longBreakConfigTitle;

  /// No description provided for @presetFast.
  ///
  /// In en, this message translates to:
  /// **'Fast 15/3 x4'**
  String get presetFast;

  /// No description provided for @presetClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic 25/5 x4'**
  String get presetClassic;

  /// No description provided for @presetDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep 50/10 x3'**
  String get presetDeep;

  /// No description provided for @settingsPersistentNotif.
  ///
  /// In en, this message translates to:
  /// **'Persistent notification'**
  String get settingsPersistentNotif;

  /// No description provided for @settingsPersistentNotifDesc.
  ///
  /// In en, this message translates to:
  /// **'Show ongoing notification controls'**
  String get settingsPersistentNotifDesc;

  /// No description provided for @dayDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus day'**
  String get dayDetailTitle;

  /// No description provided for @totalFocus.
  ///
  /// In en, this message translates to:
  /// **'Total focus'**
  String get totalFocus;

  /// No description provided for @sessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String sessionsCount(Object count);

  /// No description provided for @noSessionsDay.
  ///
  /// In en, this message translates to:
  /// **'No sessions this day'**
  String get noSessionsDay;

  /// No description provided for @last5AlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Final 5s alert'**
  String get last5AlertTitle;

  /// No description provided for @last5AlertDesc.
  ///
  /// In en, this message translates to:
  /// **'Sound & flash during last 5 seconds'**
  String get last5AlertDesc;

  /// No description provided for @dailyGoalRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining to goal: {minutes}m'**
  String dailyGoalRemaining(Object minutes);

  /// No description provided for @last5SoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Play sound (last 5s)'**
  String get last5SoundTitle;

  /// No description provided for @last5SoundDesc.
  ///
  /// In en, this message translates to:
  /// **'Audible cue in the final 5 seconds'**
  String get last5SoundDesc;

  /// No description provided for @goalProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal progress: {done}m / {total}m'**
  String goalProgressLabel(Object done, Object total);

  /// No description provided for @last5FlashTitle.
  ///
  /// In en, this message translates to:
  /// **'Flash screen (last 5s)'**
  String get last5FlashTitle;

  /// No description provided for @last5FlashDesc.
  ///
  /// In en, this message translates to:
  /// **'Visual flash during final 5 seconds'**
  String get last5FlashDesc;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @taskNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get taskNewLabel;

  /// No description provided for @taskAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get taskAdd;

  /// No description provided for @taskWorkLabel.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get taskWorkLabel;

  /// No description provided for @taskBreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get taskBreakLabel;

  /// No description provided for @taskSessionsShort.
  ///
  /// In en, this message translates to:
  /// **'Sess'**
  String get taskSessionsShort;

  /// No description provided for @taskStartFlow.
  ///
  /// In en, this message translates to:
  /// **'Start flow'**
  String get taskStartFlow;

  /// No description provided for @taskProgressSummary.
  ///
  /// In en, this message translates to:
  /// **'Tasks: {done}/{total} • {pending} pending'**
  String taskProgressSummary(Object done, Object pending, Object total);

  /// No description provided for @taskSessionProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} sessions'**
  String taskSessionProgress(Object completed, Object total);

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageSyncPreset.
  ///
  /// In en, this message translates to:
  /// **'Sync preset'**
  String get languageSyncPreset;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
