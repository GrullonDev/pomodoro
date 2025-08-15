package com.grullondev.pomodoro

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class ForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "pomodoro_fg_channel"
        const val NOTIF_ID = 9100
    }

    override fun onCreate() {
        super.onCreate()
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Pomodoro Foreground",
                NotificationManager.IMPORTANCE_LOW
            )
            nm.createNotificationChannel(channel)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Ensure service is foreground; create a basic notification if not already.
        val baseNotif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Pomodoro running")
            .setContentText("Focus session in progress")
            .setSmallIcon(R.drawable.ic_stat_pomodoro)
            .setOngoing(true)
            .build()

        try {
            startForeground(NOTIF_ID, baseNotif)
        } catch (e: Exception) {
            // If startForeground fails we still attempt to continue; avoid crashing.
        }

        if (intent != null && intent.action == "UPDATE_NOTIFICATION") {
            try {
                val remaining = intent.getLongExtra("remainingSeconds", 0L)
                val paused = intent.getBooleanExtra("paused", false)
                val title = intent.getStringExtra("title") ?: "Pomodoro"
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val text = if (paused) "Paused - ${formatRemaining(remaining)}" else formatRemaining(remaining)
                val notif = NotificationCompat.Builder(this, CHANNEL_ID)
                    .setContentTitle(title)
                    .setContentText(text)
                    .setSmallIcon(R.drawable.ic_stat_pomodoro)
                    .setOngoing(true)
                    .build()
                nm.notify(NOTIF_ID, notif)
            } catch (e: Exception) {
                // ignore update failures
            }
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        try {
            stopForeground(true)
        } catch (e: Exception) {
            // ignore
        }
        super.onDestroy()
    }

    private fun formatRemaining(sec: Long): String {
        val s = (sec % 60).toString().padStart(2, '0')
        val m = ((sec / 60) % 60).toString().padStart(2, '0')
        val h = (sec / 3600)
        return if (h > 0) String.format("%02d:%s:%s", h, m, s) else "$m:$s"
    }
}
