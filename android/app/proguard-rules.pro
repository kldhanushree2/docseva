# Firebase / Play services use reflection; keep their models intact.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Syncfusion PDF viewer + local notifications ship their own consumer rules,
# these are extra safety nets for R8 full mode.
-keep class com.syncfusion.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
