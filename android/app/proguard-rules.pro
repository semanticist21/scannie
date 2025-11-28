# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# uCrop (image_cropper)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class com.yalantis.ucrop.** { *; }

# OkHttp (referenced by uCrop)
-dontwarn okhttp3.Call
-dontwarn okhttp3.Dispatcher
-dontwarn okhttp3.OkHttpClient
-dontwarn okhttp3.OkHttpClient$Builder
-dontwarn okhttp3.Request
-dontwarn okhttp3.Request$Builder
-dontwarn okhttp3.Response
-dontwarn okhttp3.ResponseBody

# Google Play Core (deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
