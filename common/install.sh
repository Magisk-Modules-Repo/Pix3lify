ui_print " "
ui_print "   Removing remnants from past Pix3lify installs..."
# remove /data/resource-cache/overlays.list
OVERLAY='/data/resource-cache/overlays.list'
if [ -f "$OVERLAY" ] ;then
  ui_print "   Removing $OVERLAY"
  rm -f "$OVERLAY"
fi

if [ $(getprop ro.build.version.sdk) -ge 28 ]; then
  DIALER_PREF_FILE=/data/data/com.google.android.dialer/shared_prefs/dialer_phenotype_flags.xml
  if [ -f $DIALER_PREF_FILE ]; then
    ui_print " "
    ui_print "   Enabling Google's Call Screening..."
    # Enabling Google's Call Screening
    sed -i -e 's/name="G__speak_easy_bypass_locale_check" value="false"/name="G__speak_easy_bypass_locale_check" value="true"/g' $DIALER_PREF_FILE
    sed -i -e 's/name="G__speak_easy_enable_listen_in_button" value="false"/name="G__speak_easy_enable_listen_in_button" value="true"/g' $DIALER_PREF_FILE
    sed -i -e 's/name="__data_rollout__SpeakEasy.OverrideUSLocaleCheckRollout__launched__" value="false"/name="__data_rollout__SpeakEasy.OverrideUSLocaleCheckRollout__launched__" value="true"/g' $DIALER_PREF_FILE
    sed -i -e 's/name="G__enable_speakeasy_details" value="false"/name="G__enable_speakeasy_details" value="true"/g' $DIALER_PREF_FILE
    sed -i -e 's/name="G__speak_easy_enabled" value="false"/name="G__speak_easy_enabled" value="true"/g' $DIALER_PREF_FILE
    sed -i -e 's/name="G__speakeasy_show_privacy_tour" value="false"/name="G__speakeasy_show_privacy_tour" value="true"/g' $DIALER_PREF_FILE
    sed -i -e 's/name="__data_rollout__SpeakEasy.SpeakEasyDetailsRollout__launched__" value="false"/name="__data_rollout__SpeakEasy.SpeakEasyDetailsRollout__launched__" value="true"/g' $DIALER_PREF_FILE
    sed -i -e 's/name="__data_rollout__SpeakEasy.CallScreenOnPixelTwoRollout__launched__" value="false"/name="__data_rollout__SpeakEasy.CallScreenOnPixelTwoRollout__launched__" value="true"/g' $DIALER_PREF_FILE
    sed -i -e 's/name="G__speakeasy_postcall_survey_enabled" value="false"/name="G__speakeasy_postcall_survey_enabled" value="true"/g' $DIALER_PREF_FILE
    am force-stop "com.google.android.dialer"
  fi


  ui_print " "
  ui_print "   Enabling Google's Flip to Shhh..."
  # Enabling Google's Flip to Shhh
  WELLBEING_PREF_FILE=$INSTALLER/common/PhenotypePrefs.xml
  chmod 660 $WELLBEING_PREF_FILE
  WELLBEING_PREF_FOLDER=/data/data/com.google.android.apps.wellbeing/shared_prefs/
  mkdir -p $WELLBEING_PREF_FOLDER
  cp -p $WELLBEING_PREF_FILE $WELLBEING_PREF_FOLDER
  am force-stop "com.google.android.apps.wellbeing"
fi

# Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
KEYCHECK=$INSTALLER/common/keycheck
chmod 755 $KEYCHECK

keytest() {
  ui_print " - Vol Key Test -"
  ui_print "   Press Vol Up:"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
  return 0
}

choose() {
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while (true); do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events
    if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
      break
    fi
  done
  if (`cat $INSTALLER/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
    return 0
  else
    return 1
  fi
}

chooseold() {
  # Calling it first time detects previous input. Calling it second time will do what we want
  $KEYCHECK
  $KEYCHECK
  SEL=$?
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    ui_print "   Vol key not detected!"
    abort "   Use name change method in TWRP"
  fi
}

# if keytest; then
#   FUNCTION=choose
# else
FUNCTION=chooseold
# ui_print "   ! Legacy device detected! Using old keycheck method"
ui_print " "
ui_print " - Vol Key Programming -"
ui_print "   Press Vol Up:"
$FUNCTION "UP"
ui_print "   Press Vol Down:"
$FUNCTION "DOWN"
# fi

ui_print " "
ui_print " - Select Option -"
ui_print "   Do you want overlays (theme accent and rounded corners) enabled:"
ui_print "   Vol Up = Yes, Vol Down = No"
if $FUNCTION; then
  ui_print " "
  ui_print "   Enabling overlays..."
else
  ui_print " "
  ui_print "   Disabling overlays..."
  sed -i -e 's/ro.boot.vendor.overlay.theme/# ro.boot.vendor.overlay.theme/g' $INSTALLER/common/system.prop
fi
