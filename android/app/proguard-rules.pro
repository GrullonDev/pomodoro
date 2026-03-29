# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase & Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# ML Kit specific (prevents text recognition crashes in release)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.odml.image.** { *; }

# Generic
-dontwarn io.flutter.plugin.**
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**

# Play Store Split Support (Flutter)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Wear OS notification extensions (androidx.core — no extra dependency needed)
-keep class androidx.core.app.NotificationCompat$WearableExtender { *; }
-keep class androidx.core.app.NotificationCompat$Action { *; }
