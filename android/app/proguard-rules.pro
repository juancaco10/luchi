# Add project specific ProGuard rules here.

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Hive (uses reflection-free generated adapters, but keep type adapters if/when added)
-keep class hive.** { *; }
-keep class * extends com.hivedb.** { *; }

# Keep model classes used for Hive/JSON (de)serialization
-keep class com.guardianes.luciernagas.** { *; }
