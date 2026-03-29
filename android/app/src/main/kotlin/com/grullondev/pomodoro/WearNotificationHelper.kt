package com.grullondev.pomodoro

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat

/**
 * Centralises all Wear OS notification construction and haptic patterns.
 *
 * Key design decisions:
 *  - Uses NotificationCompat.WearableExtender (part of androidx.core, always available via
 *    Flutter embedding — no additional Gradle dependency needed).
 *  - All notification work happens in the ForegroundService process so it survives when the
 *    Dart/Flutter engine is suspended in the background.
 *  - Two distinct notification channels:
 *      · pomodoro_fg_channel (IMPORTANCE_LOW)  — ambient timer, no buzz on watch
 *      · pomodoro_wear_alerts (IMPORTANCE_HIGH) — phase transitions / completion, buzzes watch
 *  - WearableExtender is gracefully ignored on phones without a paired Wear OS device.
 */
object WearNotificationHelper {

    const val WEAR_ALERT_CHANNEL_ID = "pomodoro_wear_alerts"
    const val WEAR_ALERT_NOTIF_ID   = 9101

    // Vibration patterns: [delay_ms, on_ms, off_ms, on_ms, ...]
    // work→break: 3 medium pulses (signal: slow down)
    val PATTERN_WORK_TO_BREAK = longArrayOf(0L, 180L, 100L, 180L, 100L, 180L)
    // break→work: 2 short sharp taps (signal: focus now)
    val PATTERN_BREAK_TO_WORK = longArrayOf(0L, 80L, 60L, 80L)
    // all sessions complete: one long sustained pulse (signal: done)
    val PATTERN_COMPLETED     = longArrayOf(0L, 600L)

    /**
     * Builds the ongoing foreground service notification extended for Wear OS.
     *
     * The returned Notification is shown on the phone via ForegroundService.startForeground()
     * and is automatically mirrored to any paired Wear OS watch. The WearableExtender:
     *  - Adds Pause/Resume and Skip action buttons on the watch card
     *  - Adds a second page (swipe left on watch) showing session progress
     *  - Keeps the content intent available offline (watch can tap to open phone app)
     */
    fun buildWearableNotification(
        context: Context,
        channelId: String,
        title: String,
        remainingSeconds: Long,
        paused: Boolean,
        session: Int,
        totalSessions: Int,
        phase: String,
        tapIntent: PendingIntent,
    ): Notification {
        val timeText    = formatRemaining(remainingSeconds)
        val contentText = if (paused) "⏸ $timeText" else timeText
        val sessionHint = "Session $session/$totalSessions"

        // PendingIntents for watch action buttons — routed through TimerControlReceiver
        val pauseResumePi = PendingIntent.getBroadcast(
            context, 0,
            Intent(context, TimerControlReceiver::class.java).apply {
                action = TimerControlReceiver.ACTION_PAUSE_RESUME
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val skipPi = PendingIntent.getBroadcast(
            context, 1,
            Intent(context, TimerControlReceiver::class.java).apply {
                action = TimerControlReceiver.ACTION_SKIP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val pauseLabel = if (paused) "Resume" else "Pause"
        val phaseLabel = if (phase == "work") "Focus" else "Break"

        // Action objects reused on both the phone notification and the WearableExtender
        val pauseAction = NotificationCompat.Action.Builder(
            R.drawable.ic_stat_pomodoro, pauseLabel, pauseResumePi
        ).build()
        val skipAction = NotificationCompat.Action.Builder(
            R.drawable.ic_stat_pomodoro, "Skip", skipPi
        ).build()

        // Second page shown on the watch when the user swipes left
        val sessionPage = NotificationCompat.Builder(context, channelId)
            .setContentTitle(title)
            .setContentText("$sessionHint  ·  $phaseLabel")
            .build()

        val wearExtender = NotificationCompat.WearableExtender()
            .addAction(pauseAction)
            .addAction(skipAction)
            .addPage(sessionPage)
            .setContentIntentAvailableOffline(true)

        return NotificationCompat.Builder(context, channelId)
            .setContentTitle(title)
            .setContentText(contentText)
            .setSubText(sessionHint)           // shown below title on watch face
            .setSmallIcon(R.drawable.ic_stat_pomodoro)
            .setOngoing(true)
            .setContentIntent(tapIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .addAction(pauseAction)             // also visible on phone notification
            .addAction(skipAction)
            .extend(wearExtender)
            .build()
    }

    /**
     * Posts a HIGH-importance alert notification that wakes the watch screen and
     * buzzes it with a pattern specific to the phase event.
     *
     * This is intentionally a SEPARATE notification (ID 9101) from the ongoing timer
     * (ID 9100) so the user gets a clear sensory signal on their wrist.
     *
     * @param event One of: "work_to_break", "break_to_work", "completed"
     */
    fun postTransitionAlert(context: Context, event: String, title: String) {
        ensureAlertChannelCreated(context)

        val (alertTitle, alertBody, pattern) = when (event) {
            "work_to_break" -> Triple(
                "Break Time! ☕",
                "$title — Take a rest",
                PATTERN_WORK_TO_BREAK
            )
            "break_to_work" -> Triple(
                "Focus Time! \uD83C\uDFAF",
                "$title — Back to work",
                PATTERN_BREAK_TO_WORK
            )
            "completed" -> Triple(
                "All Done! \uD83C\uDFC6",
                "$title — Sessions complete",
                PATTERN_COMPLETED
            )
            else -> return
        }

        val tapPi = PendingIntent.getActivity(
            context, 2,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, WEAR_ALERT_CHANNEL_ID)
            .setContentTitle(alertTitle)
            .setContentText(alertBody)
            .setSmallIcon(R.drawable.ic_stat_pomodoro)
            .setAutoCancel(true)
            .setTimeoutAfter(10_000L)
            .setContentIntent(tapPi)
            .setVibrate(pattern)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .extend(NotificationCompat.WearableExtender())   // forward to watch
            .build()

        try {
            (context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .notify(WEAR_ALERT_NOTIF_ID, notification)
        } catch (_: Exception) {}

        // Belt-and-suspenders: also vibrate the phone directly
        triggerDeviceVibration(context, pattern)
    }

    // ── Vibration ──────────────────────────────────────────────────────────────

    private fun triggerDeviceVibration(context: Context, pattern: LongArray) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
            } else {
                @Suppress("DEPRECATION")
                val v = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    v.vibrate(VibrationEffect.createWaveform(pattern, -1))
                } else {
                    @Suppress("DEPRECATION")
                    v.vibrate(pattern, -1)
                }
            }
        } catch (_: Exception) {}
    }

    // ── Channel management ────────────────────────────────────────────────────

    private fun ensureAlertChannelCreated(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(WEAR_ALERT_CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            WEAR_ALERT_CHANNEL_ID,
            "Pomodoro Phase Alerts",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Alerts sent to the watch when a Pomodoro phase changes"
            enableVibration(true)
            vibrationPattern = PATTERN_WORK_TO_BREAK
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        nm.createNotificationChannel(channel)
    }

    // ── Utilities ──────────────────────────────────────────────────────────────

    fun formatRemaining(sec: Long): String {
        val s = (sec % 60).toString().padStart(2, '0')
        val m = ((sec / 60) % 60).toString().padStart(2, '0')
        val h = sec / 3600
        return if (h > 0) "%02d:%s:%s".format(h, m, s) else "$m:$s"
    }
}
