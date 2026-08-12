# Google Mobile Ads / AdMob — prevent R8 from stripping SDK classes
# (common cause of instant release-APK crash on launch / MobileAds.initialize)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.internal.ads.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.ads.**
-dontwarn com.google.android.gms.internal.ads.**

# User Messaging Platform (UMP) pulled in by google_mobile_ads
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.ump.**
