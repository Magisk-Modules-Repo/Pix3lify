keytest() {
  ui_print " - Vol Key Test -"
  ui_print "   Press Vol Up:"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
  return 0
}

choose() {
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while true; do
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
  $INSTALLER/common/keycheck
  $INSTALLER/common/keycheck
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

# Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
KEYCHECK=$INSTALLER/common/keycheck
chmod 755 $KEYCHECK

if keytest; then
  FUNCTION=choose
else
  FUNCTION=chooseold
  ui_print "   ! Legacy device detected! Using old keycheck method"
  ui_print " "
  ui_print " - Vol Key Programming -"
  ui_print "   Press Vol Up:"
  $FUNCTION "UP"
  ui_print "   Press Vol Down:"
  $FUNCTION "DOWN"
fi

ignorewarning() {
  ui_print "   DO YOU WANT TO IGNORE OUR WARNING AND RISK BOOTLOOPS?"
  ui_print "   Vol Up = Yes, Vol Down = No"
  if $FUNCTION; then
    ui_print " "
    ui_print "   Ignoring warning..."
  else
    ui_print " "
    ui_print "   Exiting..."
    abort
  fi
}

if [ "$PX1" ] || [ "$PX1XL" ] || [ "$PX2" ] || [ "$PX2XL" ] || [ "$PX3" ] || [ "$PX3XL" ] || [ "$N5X" ] || [ "$N6P" ]; then
  ui_print " "
  ui_print "   Pix3lify is only for non-Google devices!"
  ignorewarning
fi

if [ "$OOS" ]; then
  ui_print " "
  ui_print "   Pix3lify has a hard time with OnePlus devices!"
  ignorewarning
fi

ui_print " "
ui_print " - Overlay Options -"
ui_print "   Do you want the Pixel accent or overlay features enabled?"
ui_print "   Vol Up = Yes, Vol Down = No"
if $FUNCTION; then
  ui_print " "
  ui_print " - Overlay Options -"
  ui_print "   Do you want the Pixel accent enabled?"
  ui_print "   Vol Up = Yes, Vol Down = No"
  if $FUNCTION; then
    ui_print " "
    ui_print "   Enabling overlays and Pixel accent..."
  else
    ui_print " "
    ui_print "   Enabling overlay features..."
    sed -i -e 's/ro.boot.vendor.overlay.theme/# ro.boot.vendor.overlay.theme/g' $INSTALLER/common/system.prop
    rm -rf $INSTALLER/system/vendor/overlay/Pixel
    rm -rf /data/resource-cache
    rm -rf /data/dalvik-cache
    ui_print "   Dalvik-Cache has been cleared!"
    ui_print "   Next boot may take a little longer to boot!"
  fi
else
  ui_print " "
  ui_print "   Disabling Pixel accent and overlay features..."
  sed -i -e 's/ro.boot.vendor.overlay.theme/# ro.boot.vendor.overlay.theme/g' $INSTALLER/common/system.prop
  rm -rf $INSTALLER/system/vendor/overlay/Pixel
  rm -f $INSTALLER/system/vendor/overlay/Pix3lify.apk
  rm -rf /data/resource-cache
  rm -rf /data/dalvik-cache
  ui_print "   Dalvik-Cache has been cleared!"
  ui_print "   Next boot may take a little longer to boot!"
fi

ui_print " "
ui_print "   Removing remnants from past Pix3lify installs..."
# remove /data/resource-cache/overlays.list
OVERLAY='/data/resource-cache/overlays.list'
if [ -f "$OVERLAY" ] ;then
  ui_print "   Removing $OVERLAY"
  rm -f "$OVERLAY"
fi

if [ $API -ge 28 ]; then
  ui_print " "
  ui_print "   Enabling Google's Call Screening..."
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

if [ $API -ge 27 ]; then
  rm -rf $INSTALLER/system/framework
fi
