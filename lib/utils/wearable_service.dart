import 'dart:io';

import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/timer/timer_bloc.dart';
import 'package:pomodoro/utils/dnd.dart';
import 'package:pomodoro/utils/notifications/notifications.dart';

/// Singleton coordination layer for Wear OS (Android) and Apple Watch (iOS)
/// smartwatch integration.
///
/// Design:
///  - Reads the existing 'wearable_support_enabled' flag from [SessionRepository]
///    without modifying that class.
///  - All methods are no-ops when the flag is disabled — zero overhead.
///  - Degrades silently on phones without a paired watch; WearableExtender and
///    notification vibration patterns are simply ignored by the OS.
///  - Android path: enriches ForegroundService broadcasts with session/phase
///    context so [WearNotificationHelper] can build watch-extended notifications.
///  - iOS path: enhanced notification categories (TIMER_COMPLETE with
///    .allowAnnouncement) ensure Apple Watch mirrors phase alerts via Siri.
class WearableService {
  WearableService._();
  static final WearableService instance = WearableService._();

  bool _enabled = false;
  bool _initialized = false;
  final _repo = SessionRepository();

  // ── Initialization ────────────────────────────────────────────────────────

  /// Call once from [_TimerViewState.initState].
  /// Reads the wearable flag from SharedPreferences.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _enabled = await _repo.isWearableSupportEnabled();
  }

  /// Refreshes the enabled flag — call if the user toggles the setting
  /// while the timer is running (e.g., from a settings sheet).
  Future<void> refresh() async {
    _enabled = await _repo.isWearableSupportEnabled();
  }

  // ── Per-tick sync ─────────────────────────────────────────────────────────

  /// Called once per second from the BlocConsumer listener in timer_screen.
  ///
  /// When wearable support is ON:
  ///   Android → sends enriched broadcast (session + phase extras) so the
  ///   native ForegroundService builds a Wear OS-extended notification card.
  ///
  /// When wearable support is OFF:
  ///   Falls back to the standard broadcast (same behaviour as before).
  ///
  /// iOS path: the persistent flutter_local_notifications notification with
  /// threadIdentifier handles Apple Watch mirroring automatically; no extra
  /// call is needed here.
  void onTimerTick({
    required int remainingSeconds,
    required bool paused,
    required bool isWork,
    required String title,
    required int session,
    required int totalSessions,
  }) {
    if (Platform.isAndroid) {
      if (_enabled) {
        Dnd.updateForegroundNotificationWithWear(
          remainingSeconds: remainingSeconds,
          paused: paused,
          isWork: isWork,
          title: title,
          session: session,
          totalSessions: totalSessions,
        );
      } else {
        Dnd.updateForegroundNotification(
          remainingSeconds: remainingSeconds,
          paused: paused,
          isWork: isWork,
          title: title,
        );
      }
    } else if (Platform.isIOS && _enabled) {
      // Send real-time state to Apple Watch via WatchConnectivity.
      // Degrades silently when no watch is paired.
      Dnd.sendWatchState(
        remainingSeconds: remainingSeconds,
        paused: paused,
        isWork: isWork,
        title: title,
        session: session,
        totalSessions: totalSessions,
      );
    }
  }

  // ── Phase transition alert ────────────────────────────────────────────────

  /// Called when the timer transitions between work and break phases (or when
  /// a new session begins).
  ///
  /// Android: triggers [WearNotificationHelper.postTransitionAlert] via a
  ///   broadcast, which posts a HIGH-importance notification that buzzes the
  ///   Wear OS watch with a phase-specific vibration pattern.
  ///
  /// Both platforms: posts [NotificationService.showPhaseTransitionAlert]
  ///   which vibrates the phone and (on iOS) mirrors to Apple Watch via
  ///   the TIMER_COMPLETE category with .allowAnnouncement.
  Future<void> onPhaseTransition({
    required TimerPhase fromPhase,
    required TimerPhase toPhase,
    required int session,
    required int totalSessions,
    required String phaseTitle,
  }) async {
    if (!_enabled) return;

    final isWorkPhase = toPhase == TimerPhase.work;
    final event      = isWorkPhase ? 'break_to_work' : 'work_to_break';
    final alertTitle = isWorkPhase ? 'Focus Time! \uD83C\uDFAF' : 'Break Time! \u2615';
    final alertBody  = isWorkPhase
        ? 'Session $session of $totalSessions — Start focusing'
        : 'Session $session of $totalSessions — Take a rest';

    if (Platform.isAndroid) {
      await Dnd.triggerWearHaptic(event: event, title: phaseTitle);
    }

    // Both platforms: flutter_local_notifications for phone buzz + iOS watch
    await NotificationService.showPhaseTransitionAlert(
      title: alertTitle,
      body: alertBody,
      isWorkPhase: isWorkPhase,
    );
  }

  // ── Session completed ─────────────────────────────────────────────────────

  /// Called when all sessions are finished.
  ///
  /// Android: sends a 'completed' haptic event to the watch (one long pulse).
  /// iOS: [NotificationService.showTimerFinishedNotification] already uses
  ///   TIMER_COMPLETE with .allowAnnouncement — Apple Watch announces it.
  Future<void> onSessionCompleted({
    required int totalSessions,
    required int workMinutes,
  }) async {
    if (!_enabled) return;

    if (Platform.isAndroid) {
      await Dnd.triggerWearHaptic(event: 'completed', title: 'Pomodoro');
    }
    // iOS side is handled by the existing showTimerFinishedNotification call
    // in timer_screen.dart — no duplicate call needed here.
  }
}
