# Supabase - Keep everything
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }
-keepattributes *Annotation*
-keepnames class io.supabase.** { *; }
-keepnames class com.supabase.** { *; }

# Keep all config classes and their string constants
-keep class **.config.** { *; }
-keep class **.*Config { *; }
-keep class **.*Config$* { *; }
-keepclassmembers class **.config.** {
    public static final java.lang.String *;
    public static java.lang.String *;
    *;
}
-keepclassmembers class **.*Config {
    public static final java.lang.String *;
    public static java.lang.String *;
    *;
}

# Prevent string constant obfuscation
-keepclassmembers class * {
    public static final java.lang.String supabaseUrl;
    public static final java.lang.String supabaseAnonKey;
    public static final java.lang.String geminiApiKey;
    public static java.lang.String getSupabaseUrl();
    public static java.lang.String getSupabaseAnonKey();
}

# Gson (used by Supabase)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp (used by Supabase)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keepnames class okhttp3.** { *; }

# Retrofit (if used)
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Signature
-keepattributes Exceptions

# Keep all model classes
-keep class io.supabase.gotrue.types.** { *; }
-keep class io.supabase.postgrest.** { *; }
-keep class io.supabase.realtime.** { *; }
-keep class io.supabase.storage.** { *; }

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Isar
-keep class io.isar.** { *; }
-dontwarn io.isar.**
