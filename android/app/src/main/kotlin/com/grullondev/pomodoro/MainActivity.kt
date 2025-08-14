package com.grullondev.pomodoro

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
	private val CHANNEL = "pomodoro/dnd"

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"isPolicyGranted" -> {
					val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
					result.success(if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) nm.isNotificationPolicyAccessGranted else true)
				}
				"gotoPolicySettings" -> {
					val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
					intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
					startActivity(intent)
					result.success(null)
				}
				"getCurrentFilter" -> {
					val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
					val filter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) nm.currentInterruptionFilter else NotificationManager.INTERRUPTION_FILTER_ALL
					result.success(filter)
				}
				"setInterruptionFilter" -> {
					val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
					val filter = (call.argument<Int>("filter") ?: NotificationManager.INTERRUPTION_FILTER_ALL)
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
						// Check that the app has been granted notification policy access before attempting to change DND.
						if (nm.isNotificationPolicyAccessGranted) {
							try {
								nm.setInterruptionFilter(filter)
								result.success(null)
							} catch (se: SecurityException) {
								// Return a structured error to Dart so it can fallback to app-silent mode.
								result.error("PERMISSION_DENIED", "Notification policy access denied", null)
							}
						} else {
							result.error("PERMISSION_DENIED", "Notification policy access denied", null)
						}
					} else {
						result.error("UNSUPPORTED", "DND not supported", null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}
}
