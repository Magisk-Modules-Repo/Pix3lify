# This script will be executed in late_start service mode
# More info in the main Magisk thread

am force-stop "com.google.android.dialer"

if [ $API -ge 28 ] && [ "$FULL" ]; then
  pm enable "com.google.android.apps.wellbeing/com.google.android.apps.wellbeing.autodnd.ui.AutoDndGesturesSettingsActivity"
  if [[ $(pm list packages "com.google.android.soundpicker") ]]; then
  pm grant com.google.android.soundpicker android.permission.READ_EXTERNAL_STORAGE
  fi
fi