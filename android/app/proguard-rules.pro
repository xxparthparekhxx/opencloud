# Flutter ProGuard rules (based on the standard Flutter app template).
# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   https://developer.android.com/studio/build/shrink-code.html

# Keep the Flutter application entry points.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native method names for Dart/Flutter interop.
-keepclasseswithmembers class * {
    native <methods>;
}

# Keep R class references.
-keep class com.xxparthparekhxx.opencloud.R { *; }
-keep class com.xxparthparekhxx.opencloud.R$* { *; }

# Firebase / Google Play Services conservative keeps.
# These keep commonly reflective Firebase/Play Services classes from being
# shrunk away when minifyEnabled is true for release builds.
-keep com.google.firebase.** { *; }
-keep com.google.android.gms.** { *; }
-keep class com.google.firebase.components.ComponentRegistrar { *; }

# Gson (used by many Firebase/Play Services internals).
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.stream.** { *; }
-keep class com.google.gson.** { *; }

# Do not shrink Flutter's own dart entrypoint symbols.
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.embedding.engine.dart.DartExecutor { *; }
