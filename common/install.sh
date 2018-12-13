ui_print " "
ui_print "   Enabling Google's Call Screening..."
# Enabling Google's Call Screening
DIALER_PREF_FILE=/data/data/com.google.android.dialer/shared_prefs/dialer_phenotype_flags.xml
if [ -f $DIALER_PREF_FILE ]; then
  sed -i -e 's/name="G__speak_easy_bypass_locale_check" value="false"/name="G__speak_easy_bypass_locale_check" value="true"/g' $DIALER_PREF_FILE
  sed -i -e 's/name="G__speak_easy_enable_listen_in_button" value="false"/name="G__speak_easy_enable_listen_in_button" value="true"/g' $DIALER_PREF_FILE
  sed -i -e 's/name="__data_rollout__SpeakEasy.OverrideUSLocaleCheckRollout__launched__" value="false"/name="__data_rollout__SpeakEasy.OverrideUSLocaleCheckRollout__launched__" value="true"/g' $DIALER_PREF_FILE
  sed -i -e 's/name="G__enable_speakeasy_details" value="false"/name="G__enable_speakeasy_details" value="true"/g' $DIALER_PREF_FILE
  sed -i -e 's/name="G__speak_easy_enabled" value="false"/name="G__speak_easy_enabled" value="true"/g' $DIALER_PREF_FILE
  sed -i -e 's/name="G__speakeasy_show_privacy_tour" value="false"/name="G__speakeasy_show_privacy_tour" value="true"/g' $DIALER_PREF_FILE
  sed -i -e 's/name="__data_rollout__SpeakEasy.SpeakEasyDetailsRollout__launched__" value="false"/name="__data_rollout__SpeakEasy.SpeakEasyDetailsRollout__launched__" value="true"/g' $DIALER_PREF_FILE
  sed -i -e 's/name="__data_rollout__SpeakEasy.CallScreenOnPixelTwoRollout__launched__" value="false"/name="__data_rollout__SpeakEasy.CallScreenOnPixelTwoRollout__launched__" value="true"/g' $DIALER_PREF_FILE
  am force-stop "com.google.android.dialer"
fi

ui_print " "
ui_print "   Enabling Google's Flip to Shhh..."
# Enabling Google's Flip to Shhh
WELLBEING_PREF_FILE=/data/data/com.google.android.apps.wellbeing/shared_prefs/PhenotypePrefs.xml
if [ -f $WELLBEING_PREF_FILE ]; then
  sed -i -e 's/name="support_auto_dnd_gesture" value="false"/name="support_auto_dnd_gesture" value="true"/g' $WELLBEING_PREF_FILE
  sed -i -e 's/name="auto_dnd_device_supported" value="false"/name="auto_dnd_device_supported" value="true"/g' $WELLBEING_PREF_FILE
  am force-stop "com.google.android.apps.wellbeing"
fi

keytest() {
  ui_print " - Vol Key Test -"
  ui_print "   Press Vol Up:"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
  return 0
}

chooseport() {
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

chooseportold() {
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

# GET LAUNCHER FROM ZIP NAME
case $(basename $ZIP) in
  *customized*|*Customized*|*CUSTOMIZED*) LAUNCHER=customized;;
  *lawnchair*|*Lawnchair*|*LAWNCHAIR*) LAUNCHER=lawnchair;;
  *stock*|*Stock*|*STOCK*) LAUNCHER=stock;;
  *rootless*|*Rootless*|*ROOTLESS*) LAUNCHER=rootless	;;
  *ruthless*|*Ruthless*|*RUTHLESS*) LAUNCHER=ruthless;;
esac

# Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
KEYCHECK=$INSTALLER/common/keycheck
chmod 755 $KEYCHECK

ui_print " "
ui_print "   Removing remnants from past Pix3lify installs..."
# remove /data/resource-cache/overlays.list
OVERLAY='/data/resource-cache/overlays.list'
if [ -f "$OVERLAY" ] ;then
  ui_print "   Removing $OVERLAY"
  rm -f "$OVERLAY"
  rm -f $INSTALLER/system/priv-app/PixelLauncher/PixelLauncher.apk
fi

ui_print " "
if [ -z $LAUNCHER ]; then
  if keytest; then
    FUNCTION=chooseport
  else
    FUNCTION=chooseportold
    ui_print "   ! Legacy device detected! Using old keycheck method"
    ui_print " "
    ui_print "- Vol Key Programming -"
    ui_print "   Press Vol Up Again:"
    $FUNCTION "UP"
    ui_print "   Press Vol Down"
    $FUNCTION "DOWN"
  fi
  ui_print " "
  ui_print "- Do you want to install a Launcher?"
  ui_print "   Vol+ = Install Launcher"
  ui_print "   Vol- = Do NOT install a Launcher"
  if $FUNCTION; then
    ui_print " "
    ui_print " - Select Launcher -"
    ui_print "   Choose which Launcher you want installed:"
    ui_print "   Vol+ = Pixel Launcher (Android 9+ only), Vol- = Other Launcher choices"
    if $FUNCTION; then
      ui_print " "
      ui_print "   Installing Pixel Launcher..."
      LAUNCHER=stock
    else
      ui_print " "
      ui_print " - Select Custom Launcher -"
      ui_print "   Choose which custom Pixel Launcher you want installed:"
      ui_print "   Vol+ = Customized Pixel Launcher, Vol- = Other Launcher choices"
      if $FUNCTION; then
        ui_print " "
        ui_print "   Installing Customized Pixel Launcher..."
        LAUNCHER=customized
      else
        ui_print " "
        ui_print " - Select Custom Launcher -"
        ui_print "   Choose which custom Pixel Launcher you want installed:"
        ui_print "   Vol+ = Ruthless Launcher, Vol- = Other Launcher choices"
        if $FUNCTION; then
          ui_print " "
          ui_print "   Installing Shubbyy's Ruthless Launcher..."
          LAUNCHER=ruthless
        else
          ui_print " "
          ui_print " - Select Custom Launcher -"
          ui_print "   Choose which custom Pixel Launcher you want installed:"
          ui_print "   Vol+ = Rootless Launcher, Vol- = Lawnchair"
          if $FUNCTION; then
            ui_print " "
            ui_print "   Installing Amir's Rootless Launcher..."
            LAUNCHER=rootless
          else
            ui_print " "
            ui_print "   Installing Lawnchair..."
            LAUNCHER=lawnchair
          fi
        fi
      fi
    fi
  else
    ui_print "   Skip installing launchers..."
  fi
else
  ui_print "   Launcher specified in zipname!"
fi

if [ ! -z $LAUNCHER ]; then
  mkdir -p $INSTALLER/system/priv-app/PixelLauncher
  cp -f $INSTALLER/custom/$LAUNCHER/PixelLauncher.apk $INSTALLER/system/priv-app/PixelLauncher/PixelLauncher.apk
fi

# backup
if [ -f /data/data/com.google.android.apps.nexuslauncher/databases/launcher.db ]; then
  ui_print " "
  ui_print " - Select Backup -"
  ui_print "   Found previous home screens, do you want to backup?"
  ui_print "   Vol+ = Create backup, Vol- = Do NOT create backup"
  if $FUNCTION; then
    ui_print " "
    ui_print "   Backing up home screens.."
    cp -f /data/data/com.google.android.apps.nexuslauncher/databases/launcher.db /data/media/0/.launcher.db.backup
    NORESTORE=1
  else
    ui_print " "
    ui_print "   Did not backup!"
  fi
fi

# restore
if [ -f /data/media/0/.launcher.db.backup ] && [ -z $NORESTORE ]; then
  ui_print " "
  ui_print " - Select Restore -"
  ui_print "   Found backup of home screens, do you want to restore?"
  ui_print "   Vol+ = Restore backup, Vol- = Do NOT restore"
  if $FUNCTION; then
    ui_print " "
    ui_print "   Restoring home screens.."
    if [ ! -d /data/data/com.google.android.apps.nexuslauncher/databases ]; then
      touch /data/media/0/.launcher.restore
    else
      cp -f /data/media/0/.launcher.db.backup /data/data/com.google.android.apps.nexuslauncher/databases/launcher.db
    fi
  else
    ui_print " "
    ui_print "   Did not restore!"
  fi
fi
