package com.grullondev.pomodoro

import android.Manifest
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

	private val CHANNEL = "pomodoro/dnd"

	// Dynamic receiver that picks up watch action relay from TimerControlReceiver
	// and forwards it to Dart via MethodChannel.invokeMethod("onWatchAction").
	private var watchActionReceiver: BroadcastReceiver? = null
	private var watchActionChannel: MethodChannel?      = null

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
		watchActionChannel = channel

		channel.setMethodCallHandler { call, result ->
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

				"gotoAppNotificationSettings" -> {
					try {
						val intent = Intent()
						if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
							intent.action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
							intent.putExtra(Settings.EXTRA_APP_PACKAGE, this@MainActivity.packageName)
						} else {
							intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
							intent.data = Uri.parse("package:${this@MainActivity.packageName}")
						}
						intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(intent)
						result.success(null)
					} catch (e: Exception) {
						result.error("OPEN_SETTINGS_FAILED", e.message, null)
					}
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
						if (nm.isNotificationPolicyAccessGranted) {
							try {
								nm.setInterruptionFilter(filter)
								result.success(null)
							} catch (se: SecurityException) {
								result.error("PERMISSION_DENIED", "Notification policy access denied", null)
							} catch (iae: IllegalArgumentException) {
								try { nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL) } catch (_: Exception) {}
								result.error("INVALID_FILTER", "Invalid interruption filter $filter", null)
							}
						} else {
							result.error("PERMISSION_DENIED", "Notification policy access denied", null)
						}
					} else {
						result.error("UNSUPPORTED", "DND not supported", null)
					}
				}

				"startLockTask" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
						try {
							this@MainActivity.startLockTask()
							result.success(true)
						} catch (e: Exception) {
							result.error("LOCK_FAILED", e.message, null)
						}
					} else {
						result.error("UNSUPPORTED", "Lock task not supported on this OS", null)
					}
				}

				"stopLockTask" -> {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
						try {
							this@MainActivity.stopLockTask()
							result.success(true)
						} catch (e: Exception) {
							result.error("LOCK_FAILED", e.message, null)
						}
					} else {
						result.error("UNSUPPORTED", "Lock task not supported on this OS", null)
					}
				}

				"startForegroundService" -> {
					try {
						@Suppress("UNCHECKED_CAST")
						val args = call.arguments as? Map<String, Any>
						val intent = Intent(this@MainActivity, ForegroundService::class.java).apply {
							action = "START"
							if (args != null) {
								putExtra(ForegroundService.EXTRA_REMAINING,
									(args["remainingSeconds"] as? Number)?.toLong() ?: 0L)
								putExtra(ForegroundService.EXTRA_PAUSED,
									(args["paused"] as? Boolean) ?: false)
								putExtra(ForegroundService.EXTRA_TITLE,
									(args["title"] as? String) ?: "Pomodoro")
								// Wear OS context (optional — passed when wearable support is ON)
								val sess = (args["session"] as? Number)?.toInt()
								if (sess != null) putExtra(ForegroundService.EXTRA_SESSION, sess)
								val total = (args["totalSessions"] as? Number)?.toInt()
								if (total != null) putExtra(ForegroundService.EXTRA_TOTAL_SESSIONS, total)
								(args["phase"] as? String)?.let { putExtra(ForegroundService.EXTRA_PHASE, it) }
							}
						}
						if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
							this@MainActivity.startForegroundService(intent)
						} else {
							this@MainActivity.startService(intent)
						}
						result.success(true)
					} catch (e: Exception) {
						result.error("FG_START_FAILED", e.message, null)
					}
				}

				"stopForegroundService" -> {
					try {
						val intent = Intent(this@MainActivity, ForegroundService::class.java)
						this@MainActivity.stopService(intent)
						result.success(true)
					} catch (e: Exception) {
						result.error("FG_STOP_FAILED", e.message, null)
					}
				}

				"updateForegroundNotification" -> {
					try {
						@Suppress("UNCHECKED_CAST")
						val args = call.arguments as? Map<String, Any>
						if (args != null) {
							val remaining = (args["remainingSeconds"] as? Number)?.toLong() ?: 0L
							val paused    = (args["paused"] as? Boolean) ?: false
							val title     = (args["title"] as? String) ?: "Pomodoro"

							// Use sendBroadcast — works from background on all Android versions.
							// startForegroundService from background is blocked on Android 12+.
							val broadcast = Intent(ForegroundService.ACTION_SYNC).apply {
								setPackage(packageName)
								putExtra(ForegroundService.EXTRA_REMAINING, remaining)
								putExtra(ForegroundService.EXTRA_PAUSED, paused)
								putExtra(ForegroundService.EXTRA_TITLE, title)
								// Wear OS extras (present when wearable support is ON)
								val sess = (args["session"] as? Number)?.toInt()
								if (sess != null) putExtra(ForegroundService.EXTRA_SESSION, sess)
								val total = (args["totalSessions"] as? Number)?.toInt()
								if (total != null) putExtra(ForegroundService.EXTRA_TOTAL_SESSIONS, total)
								(args["phase"] as? String)?.let { putExtra(ForegroundService.EXTRA_PHASE, it) }
							}
							sendBroadcast(broadcast)
							result.success(true)
						} else {
							result.error("INVALID_ARGS", "Expected map arguments", null)
						}
					} catch (e: Exception) {
						result.error("UPDATE_FAILED", e.message, null)
					}
				}

				"triggerWearHaptic" -> {
					try {
						@Suppress("UNCHECKED_CAST")
						val args = call.arguments as? Map<String, Any>
						val event = (args?.get("event") as? String) ?: return@setMethodCallHandler result.error("INVALID_ARGS", "event required", null)
						val title = (args["title"] as? String) ?: "Pomodoro"
						val broadcast = Intent(ForegroundService.ACTION_WEAR_HAPTIC).apply {
							setPackage(packageName)
							putExtra(ForegroundService.EXTRA_WEAR_EVENT, event)
							putExtra(ForegroundService.EXTRA_TITLE, title)
						}
						sendBroadcast(broadcast)
						result.success(true)
					} catch (e: Exception) {
						result.error("WEAR_HAPTIC_FAILED", e.message, null)
					}
				}

				"requestNotificationPermission" -> {
					try {
						if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
							val granted = ContextCompat.checkSelfPermission(this@MainActivity, Manifest.permission.POST_NOTIFICATIONS) == android.content.pm.PackageManager.PERMISSION_GRANTED
							if (!granted) {
								ActivityCompat.requestPermissions(this@MainActivity, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1234)
							}
							result.success(granted)
						} else {
							result.success(true)
						}
					} catch (e: Exception) {
						result.error("PERMISSION_REQUEST_FAILED", e.message, null)
					}
				}

				else -> result.notImplemented()
			}
		}

		// Register dynamic receiver for watch action relay from TimerControlReceiver.
		// This is dynamic (not in Manifest) because it needs the live MethodChannel reference.
		registerWatchActionReceiver()
	}

	private fun registerWatchActionReceiver() {
		watchActionReceiver = object : BroadcastReceiver() {
			override fun onReceive(ctx: Context?, intent: Intent?) {
				val action = intent?.getStringExtra(TimerControlReceiver.EXTRA_WATCH_ACTION) ?: return
				// Forward watch action to Dart so TimerActionBus can dispatch it to TimerBloc
				watchActionChannel?.invokeMethod("onWatchAction", mapOf("action" to action))
			}
		}
		val filter = IntentFilter(TimerControlReceiver.ACTION_WATCH_ACTION)
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
			registerReceiver(watchActionReceiver, filter, RECEIVER_NOT_EXPORTED)
		} else {
			registerReceiver(watchActionReceiver, filter)
		}
	}

	override fun onDestroy() {
		try { watchActionReceiver?.let { unregisterReceiver(it) } } catch (_: Exception) {}
		watchActionReceiver = null
		watchActionChannel  = null
		super.onDestroy()
	}
}
