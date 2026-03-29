package com.grullondev.pomodorofocus

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class ForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "pomodoro_fg_channel"
        const val NOTIF_ID   = 9100

        // Broadcast: Dart → Service sync (timer state each second)
        const val ACTION_SYNC        = "com.grullondev.pomodoro.TIMER_SYNC"
        // Broadcast: Dart → Service haptic event (phase transition / completion)
        const val ACTION_WEAR_HAPTIC = "com.grullondev.pomodoro.WEAR_HAPTIC"

        // Intent extras — shared with MainActivity
        const val EXTRA_REMAINING      = "remainingSeconds"
        const val EXTRA_PAUSED         = "paused"
        const val EXTRA_TITLE          = "title"
        const val EXTRA_SESSION        = "session"
        const val EXTRA_TOTAL_SESSIONS = "totalSessions"
        const val EXTRA_PHASE          = "phase"        // "work" | "break"
        const val EXTRA_WEAR_EVENT     = "wearEvent"    // "work_to_break" | "break_to_work" | "completed"
    }

    // ── Timer state ───────────────────────────────────────────────────────────

    private var remainingSeconds = 0L
    private var paused           = false
    private var sessionTitle     = "Pomodoro"
    private var currentSession   = 1
    private var totalSessions    = 1
    private var phase            = "work"   // "work" | "break"

    // ── Native countdown (runs even when Dart is suspended) ───────────────────

    private val handler = Handler(Looper.getMainLooper())

    private val tickRunnable = object : Runnable {
        override fun run() {
            if (!paused && remainingSeconds > 0) {
                remainingSeconds--
                postNotification()
            }
            if (remainingSeconds > 0) {
                handler.postDelayed(this, 1_000L)
            }
        }
    }

    // ── Resources ─────────────────────────────────────────────────────────────

    private var wakeLock: PowerManager.WakeLock? = null
    private var syncReceiver: BroadcastReceiver?      = null
    private var wearHapticReceiver: BroadcastReceiver? = null

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        acquireWakeLock()
        registerSyncReceiver()
        registerWearHapticReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Sync state from intent when provided
        if (intent != null) {
            val rem = intent.getLongExtra(EXTRA_REMAINING, -1L)
            if (rem >= 0) remainingSeconds = rem
            paused = intent.getBooleanExtra(EXTRA_PAUSED, paused)
            intent.getStringExtra(EXTRA_TITLE)?.let { sessionTitle = it }
            val sess = intent.getIntExtra(EXTRA_SESSION, -1)
            if (sess > 0) currentSession = sess
            val total = intent.getIntExtra(EXTRA_TOTAL_SESSIONS, -1)
            if (total > 0) totalSessions = total
            intent.getStringExtra(EXTRA_PHASE)?.let { phase = it }
        }

        // Must call startForeground before the 5-second ANR timeout (Android 8+)
        startForegroundCompat()

        if (!paused && remainingSeconds > 0) {
            rescheduleNativeTick()
        } else {
            handler.removeCallbacks(tickRunnable)
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacks(tickRunnable)
        unregisterReceiverSafely(syncReceiver)
        unregisterReceiverSafely(wearHapticReceiver)
        syncReceiver      = null
        wearHapticReceiver = null
        releaseWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    // ── Foreground / notification ─────────────────────────────────────────────

    private fun startForegroundCompat() {
        val notif = buildNotification()
        try {
            // Android 14 (API 34) requires explicit service type in startForeground()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(NOTIF_ID, notif, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIF_ID, notif, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
            } else {
                startForeground(NOTIF_ID, notif)
            }
        } catch (e: Exception) {
            // Fallback: try without type parameter
            try { startForeground(NOTIF_ID, notif) } catch (_: Exception) {}
        }
    }

    private fun postNotification() {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIF_ID, buildNotification())
        } catch (_: Exception) {}
    }

    /**
     * Delegates to WearNotificationHelper which builds the full Wear OS-extended
     * notification with action buttons and session progress page.
     */
    private fun buildNotification() = WearNotificationHelper.buildWearableNotification(
        context        = this,
        channelId      = CHANNEL_ID,
        title          = sessionTitle,
        remainingSeconds = remainingSeconds,
        paused         = paused,
        session        = currentSession,
        totalSessions  = totalSessions,
        phase          = phase,
        tapIntent      = buildTapIntent(),
    )

    private fun buildTapIntent(): PendingIntent = PendingIntent.getActivity(
        this, 0,
        Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    // ── Native countdown ──────────────────────────────────────────────────────

    private fun rescheduleNativeTick() {
        handler.removeCallbacks(tickRunnable)
        handler.postDelayed(tickRunnable, 1_000L)
    }

    // ── Broadcast receivers ───────────────────────────────────────────────────

    /**
     * Receives timer state sync from Dart every second via sendBroadcast().
     * Uses broadcast instead of startForegroundService to avoid Android 12+ background
     * start restrictions that prevent updating notifications when the app is backgrounded.
     */
    private fun registerSyncReceiver() {
        syncReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                intent ?: return

                val rem = intent.getLongExtra(EXTRA_REMAINING, -1L)
                if (rem >= 0) remainingSeconds = rem

                val newPaused = intent.getBooleanExtra(EXTRA_PAUSED, paused)
                intent.getStringExtra(EXTRA_TITLE)?.let { sessionTitle = it }
                val sess = intent.getIntExtra(EXTRA_SESSION, -1)
                if (sess > 0) currentSession = sess
                val total = intent.getIntExtra(EXTRA_TOTAL_SESSIONS, -1)
                if (total > 0) totalSessions = total
                intent.getStringExtra(EXTRA_PHASE)?.let { phase = it }

                val wasPaused = paused
                paused = newPaused

                postNotification()

                // Restart native tick on resume
                if (wasPaused && !paused && remainingSeconds > 0) {
                    rescheduleNativeTick()
                }
                // Stop native tick on pause
                if (!wasPaused && paused) {
                    handler.removeCallbacks(tickRunnable)
                }
            }
        }
        registerReceiverCompat(syncReceiver!!, IntentFilter(ACTION_SYNC))
    }

    /**
     * Receives haptic event requests from Dart (phase transition / completion).
     * Delegates to WearNotificationHelper which posts a HIGH-importance alert
     * notification that buzzes the paired Wear OS watch.
     */
    private fun registerWearHapticReceiver() {
        wearHapticReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                intent ?: return
                val event = intent.getStringExtra(EXTRA_WEAR_EVENT) ?: return
                WearNotificationHelper.postTransitionAlert(
                    this@ForegroundService, event, sessionTitle
                )
            }
        }
        registerReceiverCompat(wearHapticReceiver!!, IntentFilter(ACTION_WEAR_HAPTIC))
    }

    private fun registerReceiverCompat(receiver: BroadcastReceiver, filter: IntentFilter) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }
    }

    private fun unregisterReceiverSafely(receiver: BroadcastReceiver?) {
        try { receiver?.let { unregisterReceiver(it) } } catch (_: Exception) {}
    }

    // ── WakeLock ──────────────────────────────────────────────────────────────

    private fun acquireWakeLock() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "pomodoro::TimerWakeLock"
            ).also {
                it.acquire(6 * 60 * 60 * 1_000L)   // max 6 hours
            }
        } catch (_: Exception) {}
    }

    private fun releaseWakeLock() {
        try { if (wakeLock?.isHeld == true) wakeLock?.release() } catch (_: Exception) {}
        wakeLock = null
    }

    // ── Notification channel ──────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Pomodoro Timer",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows the active Pomodoro timer countdown"
            setShowBadge(false)
            enableVibration(false)
            enableLights(false)
        }
        nm.createNotificationChannel(channel)
    }
}
