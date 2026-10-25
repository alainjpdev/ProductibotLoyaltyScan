# Proguard rules for Supabase, Ktor, and Serialization
-keepattributes *Annotation*, InnerClasses, Signature, Exceptions
-keepclassmembers class * {
    @kotlinx.serialization.Serializable <fields>;
}
-keepclassmembers class * extends kotlinx.serialization.internal.GeneratedSerializer {
    *;
}
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }
-keep class com.google.mlkit.** { *; }
-dontwarn io.ktor.**
-dontwarn kotlinx.serialization.**
