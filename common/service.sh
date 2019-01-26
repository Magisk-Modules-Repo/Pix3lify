# This script will be executed in late_start service mode
# More info in the main Magisk thread

if [ $API -ge 28 ] && [ $FULL ]; then
  pm enable "com.google.android.apps.wellbeing/com.google.android.apps.wellbeing.autodnd.ui.AutoDndGesturesSettingsActivity"
  am force-stop "com.google.android.apps.wellbeing"
  if [[ $(pm list packages "com.google.android.soundpicker") ]]; then
    pm grant com.google.android.soundpicker android.permission.READ_EXTERNAL_STORAGE
  fi
fi

pm grant "com.google.android.dialer" android.permission.WRITE_EXTERNAL_STORAGE
am force-stop "com.google.android.dialer"
