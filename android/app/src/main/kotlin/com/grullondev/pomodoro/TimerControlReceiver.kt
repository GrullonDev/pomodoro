package com.grullondev.pomodoro

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receives PendingIntent broadcasts fired by Wear OS watch notification action buttons
 * (Pause/Resume and Skip) and relays them to MainActivity via a secondary internal broadcast.
 *
 * Flow:
 *   Wear OS watch button tap
 *     → Android delivers PendingIntent broadcast here (declared in AndroidManifest.xml)
 *     → We re-broadcast ACTION_WATCH_ACTION internally
 *     → MainActivity's dynamically-registered BroadcastReceiver picks it up
 *     → MethodChannel.invokeMethod("onWatchAction", {action: "toggle"|"skip"}) → Dart
 *     → TimerActionBus.instance.add(action)
 *     → TimerBloc.add(TimerPaused / TimerResumed / TimerPhaseCompleted)
 *
 * This two-step relay is necessary because:
 *  a) The PendingIntent target must be a static component (declared in Manifest).
 *  b) The MethodChannel requires the Flutter engine to be alive (MainActivity).
 *  c) If the Flutter engine is dead, the relay broadcast is simply dropped — the native
 *     ForegroundService countdown continues unaffected (graceful degradation).
 *
 * Declared in AndroidManifest.xml with android:exported="false".
 */
class TimerControlReceiver : BroadcastReceiver() {

    companion object {
        // Incoming actions from watch PendingIntents
        const val ACTION_PAUSE_RESUME = "com.grullondev.pomodoro.WATCH_PAUSE_RESUME"
        const val ACTION_SKIP         = "com.grullondev.pomodoro.WATCH_SKIP"

        // Internal relay picked up by MainActivity's dynamic receiver
        const val ACTION_WATCH_ACTION = "com.grullondev.pomodoro.WATCH_ACTION"
        const val EXTRA_WATCH_ACTION  = "watch_action"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        context ?: return

        val watchAction = when (intent?.action) {
            ACTION_PAUSE_RESUME -> "toggle"
            ACTION_SKIP         -> "skip"
            else                -> return
        }

        context.sendBroadcast(
            Intent(ACTION_WATCH_ACTION).apply {
                setPackage(context.packageName)  // restrict to our own process
                putExtra(EXTRA_WATCH_ACTION, watchAction)
            }
        )
    }
}
