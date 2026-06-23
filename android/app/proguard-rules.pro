# Flutter / Dart
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase (Auth, Firestore, Messaging, Storage)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep annotated members used via reflection by Firestore/Gson-style mappers
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# image_picker / file_picker / video plugins use platform reflection
-keep class androidx.lifecycle.** { *; }

# Suppress notes about missing optional desugaring classes
-dontwarn java.lang.invoke.**
