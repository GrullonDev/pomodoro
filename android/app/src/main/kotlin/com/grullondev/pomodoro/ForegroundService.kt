package com.grullondev.pomodoro

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
        const val NOTIF_ID = 9100

        // Broadcast action for Dart→Service sync updates (works from background on all API levels)
        const val ACTION_SYNC = "com.grullondev.pomodoro.TIMER_SYNC"
        const val EXTRA_REMAINING = "remainingSeconds"
        const val EXTRA_PAUSED = "paused"
        const val EXTRA_TITLE = "title"
    }

    private var remainingSeconds = 0L
    private var paused = false
    private var sessionTitle = "Pomodoro"

    // Native countdown so the notification keeps updating even when Dart is suspended
    private val handler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null
    private var syncReceiver: BroadcastReceiver? = null

    private val tickRunnable = object : Runnable {
        override fun run() {
            if (!paused && remainingSeconds > 0) {
                remainingSeconds--
                postNotification()
            }
            // Keep scheduling as long as there is time left (stopped via stopSelf / onDestroy)
            if (remainingSeconds > 0) {
                handler.postDelayed(this, 1_000L)
            }
        }
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        acquireWakeLock()
        registerSyncReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: "START"

        // Sync state from intent extras when present
        if (intent != null) {
            val rem = intent.getLongExtra(EXTRA_REMAINING, -1L)
            if (rem >= 0) remainingSeconds = rem
            paused = intent.getBooleanExtra(EXTRA_PAUSED, paused)
            intent.getStringExtra(EXTRA_TITLE)?.let { sessionTitle = it }
        }

        // Promote to foreground immediately — required before 5 s timeout on Android 8+
        startForegroundCompat()

        if (action == "START" || action == "UPDATE_NOTIFICATION") {
            // Restart the native tick only when we are not paused and have time left
            if (!paused && remainingSeconds > 0) {
                rescheduleNativeTick()
            } else {
                handler.removeCallbacks(tickRunnable)
            }
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacks(tickRunnable)
        unregisterSyncReceiverSafely()
        releaseWakeLock()
        @Suppress("DEPRECATION")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            stopForeground(true)
        }
        super.onDestroy()
    }

    // ── Foreground / notification helpers ────────────────────────────────────

    private fun startForegroundCompat() {
        val notif = buildNotification()
        try {
            // API 34 (Android 14) requires explicit foreground service type in startForeground()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIF_ID, notif,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // API 29+ also accepts the type param
                startForeground(
                    NOTIF_ID, notif,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                )
            } else {
                startForeground(NOTIF_ID, notif)
            }
        } catch (e: Exception) {
            // Fallback: try without type if the typed variant fails
            try { startForeground(NOTIF_ID, notif) } catch (_: Exception) {}
        }
    }

    private fun postNotification() {
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.notify(NOTIF_ID, buildNotification())
        } catch (_: Exception) {}
    }

    private fun buildNotification(): android.app.Notification {
        // Tap notification → reopen app
        val tapPi = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val timeText = formatRemaining(remainingSeconds)
        val contentText = if (paused) "⏸ $timeText" else timeText

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(sessionTitle)
            .setContentText(contentText)
            .setSmallIcon(R.drawable.ic_stat_pomodoro)
            .setOngoing(true)
            .setContentIntent(tapPi)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            // Show notification immediately without batching delay (Android 12+ behaviour)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    // ── Native countdown ──────────────────────────────────────────────────────

    private fun rescheduleNativeTick() {
        handler.removeCallbacks(tickRunnable)
        handler.postDelayed(tickRunnable, 1_000L)
    }

    // ── BroadcastReceiver for Dart sync ───────────────────────────────────────

    /**
     * Dart sends a broadcast (not startForegroundService) for every second update.
     * Broadcasts are delivered even when the app is in the background, and there are
     * no background-start restrictions that apply to foreground services.
     */
    private fun registerSyncReceiver() {
        syncReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                intent ?: return
                val rem = intent.getLongExtra(EXTRA_REMAINING, -1L)
                if (rem >= 0) remainingSeconds = rem
                val newPaused = intent.getBooleanExtra(EXTRA_PAUSED, paused)
                intent.getStringExtra(EXTRA_TITLE)?.let { sessionTitle = it }

                val wasPaused = paused
                paused = newPaused

                postNotification()

                // If just resumed, restart the native tick
                if (wasPaused && !paused && remainingSeconds > 0) {
                    rescheduleNativeTick()
                }
                // If just paused, stop the native tick
                if (!wasPaused && paused) {
                    handler.removeCallbacks(tickRunnable)
                }
            }
        }

        val filter = IntentFilter(ACTION_SYNC)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+: must declare RECEIVER_NOT_EXPORTED for internal broadcasts
            registerReceiver(syncReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(syncReceiver, filter)
        }
    }

    private fun unregisterSyncReceiverSafely() {
        try { syncReceiver?.let { unregisterReceiver(it) } } catch (_: Exception) {}
        syncReceiver = null
    }

    // ── WakeLock ──────────────────────────────────────────────────────────────

    private fun acquireWakeLock() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "pomodoro::TimerWakeLock"
            ).also {
                // Hold for up to 6 hours (longest realistic Pomodoro session)
                it.acquire(6 * 60 * 60 * 1_000L)
            }
        } catch (_: Exception) {}
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) wakeLock?.release()
        } catch (_: Exception) {}
        wakeLock = null
    }

    // ── Channel / channel creation ────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Pomodoro Timer",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows the active Pomodoro timer"
                setShowBadge(false)
                enableVibration(false)
                enableLights(false)
            }
            nm.createNotificationChannel(channel)
        }
    }

    // ── Utilities ─────────────────────────────────────────────────────────────

    private fun formatRemaining(sec: Long): String {
        val s = (sec % 60).toString().padStart(2, '0')
        val m = ((sec / 60) % 60).toString().padStart(2, '0')
        val h = sec / 3600
        return if (h > 0) "%02d:%s:%s".format(h, m, s) else "$m:$s"
    }
}
