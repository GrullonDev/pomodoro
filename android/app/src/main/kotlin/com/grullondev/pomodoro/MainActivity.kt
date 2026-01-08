package com.grullondev.pomodoro

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
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
								// Some OEM firmwares may reject values; fall back to ALL instead of crashing
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
						val intent = Intent(this@MainActivity, ForegroundService::class.java)
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
						val args = call.arguments as? Map<String, Any>
						if (args != null) {
							val remaining = (args["remainingSeconds"] as? Number)?.toLong() ?: 0L
							val paused = (args["paused"] as? Boolean) ?: false
							val isWork = (args["isWork"] as? Boolean) ?: true
							val title = (args["title"] as? String) ?: "Pomodoro"
							val intent = Intent(this@MainActivity, ForegroundService::class.java)
							intent.action = "UPDATE_NOTIFICATION"
							intent.putExtra("remainingSeconds", remaining)
							intent.putExtra("paused", paused)
							intent.putExtra("isWork", isWork)
							intent.putExtra("title", title)
							if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
								this@MainActivity.startForegroundService(intent)
							} else {
								this@MainActivity.startService(intent)
							}
							result.success(true)
						} else {
							result.error("INVALID_ARGS", "Expected map arguments", null)
						}
					} catch (e: Exception) {
						result.error("UPDATE_FAILED", e.message, null)
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
	}
}
