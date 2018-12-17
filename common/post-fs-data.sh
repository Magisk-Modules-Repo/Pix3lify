#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

if [[ $(pm list packages "com.google.android.apps.wellbeing") ]]; then
  pm enable "com.google.android.apps.wellbeing/com.google.android.apps.wellbeing.autodnd.ui.AutoDndGesturesSettingsActivity"
fi

# This script will be executed in post-fs-data mode
# More info in the main Magisk thread
