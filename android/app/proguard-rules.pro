# ProGuard configuration for NES Emulator performance optimization

# Keep emulator core classes
-keep class com.example.fnes.** { *; }

# Keep Flutter and Dart runtime
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Google Play Core library classes (required for deferred components)
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Optimize method invocation
-optimizationpasses 5
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*

# Class merging
-allowaccessmodification
-mergeinterfacesaggressively

# For better performance
-repackageclasses ''
-flattenpackagehierarchy ''
