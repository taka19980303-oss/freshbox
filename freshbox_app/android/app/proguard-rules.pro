# Flutter合体設定
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Hive
-keep class com.hive.** { *; }
-keepnames class * extends com.hive.** { *; }

# アプリクラス
-keep class jp.freshbox.app.** { *; }
