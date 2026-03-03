# -------------------------
# Flutter
# -------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-dontwarn io.flutter.**

# -------------------------
# Firebase Core & Analytics
# -------------------------
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# -------------------------
# Firebase Messaging (FCM)
# -------------------------
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# -------------------------
# Firebase Auth
# -------------------------
-keep class com.google.firebase.auth.** { *; }

# -------------------------
# Firestore
# -------------------------
-keep class com.google.firebase.firestore.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# -------------------------
# Kotlin
# -------------------------
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# -------------------------
# Crash stack traces (keep readable)
# -------------------------
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# -------------------------
# Prevent stripping enums
# -------------------------
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# -------------------------
# Parcelable (Android data passing)
# -------------------------
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# -------------------------
# Serializable
# -------------------------
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
