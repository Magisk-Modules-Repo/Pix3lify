keytest() {
  ui_print " - Vol Key Test -"
  ui_print "   Press Vol Up:"
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $INSTALLER/events) || return 1
  return 0
}

choose() {
  # Note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
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

SLIM=false; FULL=false; OVER=false; BOOT=false; ACC=false;
# Gets stock/limit from zip name
case $(basename $ZIP) in
  *slim*|*Slim*|*SLIM*) SLIM=true;;
  *full*|*Full*|*FULL*) FULL=true;;
  *over*|*Over*|*OVER*) OVER=true;;
  *boot*|*Boot*|*BOOT*) BOOT=true;;
  *acc*|*Acc*|*ACC*) ACC=true;;
esac

# Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
KEYCHECK=$INSTALLER/common/keycheck
chmod 755 $KEYCHECK

if [ "$PX1" ] || [ "$PX1XL" ] || [ "$PX2" ] || [ "$PX2XL" ] || [ "$PX3" ] || [ "$PX3XL" ] || [ "$N5X" ] || [ "$N6P" ] || [ "$OOS" ]; then
  ui_print " "
  if [ "$OOS" ]; then
    ui_print "   Pix3lify has been known to not work and cause issues on devices running OxygenOS!"
  else
    ui_print "   Pix3lify is only for non-Google devices!"
  fi
  ui_print "   DO YOU WANT TO IGNORE OUR WARNINGS AND RISK A BOOTLOOP?"
  ui_print "   Vol Up = Yes, Vol Down = No"
  if $FUNCTION; then
    ui_print " "
    ui_print "   Ignoring warnings..."
  else
    ui_print " "
    ui_print "   Exiting..."
    abort
  fi
fi

ui_print " "
ui_print "   Removing remnants from past Pix3lify installs..."
# Removes /data/resource-cache/overlays.list
OVERLAY='/data/resource-cache/overlays.list'
if [ -f "$OVERLAY" ]; then
  ui_print "   Removing $OVERLAY"
  rm -f "$OVERLAY"
fi

if [ "$SLIM" == false -a "$FULL" == false -a "$OVER" == false -a "$BOOT" ]; then
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

  if ! $SLIM && ! $FULL && ! $OVER && ! $BOOT && ! $ACC; then
    ui_print " "
    ui_print " - Slim Options -"
    ui_print "   Do you want to enable slim mode (heavily reduced featureset, see README)?"
    ui_print "   Vol Up = Yes, Vol Down = No"
    if $FUNCTION; then
      SLIM=true
    else
      FULL=true
    fi
    if $FULL; then
      ui_print " "
      ui_print " - Overlay Options -"
      ui_print "   Do you want the Pixel overlays enabled?"
      ui_print "   Vol Up = Yes, Vol Down = No"
      if $FUNCTION; then
        OVER=true
        ui_print " "
        ui_print " - Accent Options -"
        ui_print "   Do you want the Pixel accent enabled?"
        ui_print "   Vol Up = Yes, Vol Down = No"
        if $FUNCTION; then
          ACC=true
        fi
      fi
    fi
    ui_print " "
    ui_print " - Animation Options -"
    ui_print "   Do you want the Pixel boot animation?"
    ui_print "   Vol Up = Yes, Vol Down = No"
    if $FUNCTION; then
      BOOT=true
    fi
  else
    ui_print " Options specified in zip name!"
  fi
fi

# had to break up volume options this way for basename zip for users without working vol keys
if $SLIM; then
  ui_print " "
  ui_print "   Enabling slim mode..."
  rm -rf $INSTALLER/system/app
  rm -rf $INSTALLER/system/fonts
  rm -rf $INSTALLER/system/lib
  rm -rf $INSTALLER/system/lib64
  rm -rf $INSTALLER/system/media
  rm -rf $INSTALLER/system/priv-app
  rm -rf $INSTALLER/system/vendor/overlay/DisplayCutoutEmulationCorner
  rm -rf $INSTALLER/system/vendor/overlay/DisplayCutoutEmulationDouble
  rm -rf $INSTALLER/system/vendor/overlay/DisplayCutoutEmulationTall
  rm -rf $INSTALLER/system/vendor/overlay/DisplayCutoutNoCutout
  rm -rf $INSTALLER/system/vendor/overlay/Pixel
  sed -i 's/ro.boot.vendor.overlay.theme/# ro.boot.vendor.overlay.theme/g' $INSTALLER/common/system.prop
  rm -rf /data/resource-cache
fi

if $FULL; then
  ui_print " "
  ui_print " Full mode selected..."
  prop_process $INSTALLER/common/full.prop
  if $OVER; then
    ui_print " "
    ui_print "   Enabling overlay features..."
  else
    ui_print " "
    ui_print "   Disabling overlay features..."
    rm -f $INSTALLER/system/vendor/overlay/Pix3lify.apk
    rm -rf /data/resource-cache
    rm -rf /data/dalvik-cache
    ui_print "   Dalvik-Cache has been cleared!"
    ui_print "   Next boot may take a little longer to boot!"
  fi
  if $ACC; then
    ui_print " "
    ui_print "   Enabling Pixel accent..."
  else
    ui_print " "
    ui_print "   Disabling Pixel accent..."
    rm -rf $INSTALLER/system/vendor/overlay/Pixel
    sed -i 's/ro.boot.vendor.overlay.theme/# ro.boot.vendor.overlay.theme/g' $INSTALLER/common/system.prop
    rm -rf /data/resource-cache
  fi
fi

if $BOOT; then
  ui_print " "
  ui_print "   Enabling boot animation..."
  cp -f $INSTALLER/common/bootanimation.zip $UNITY$BFOLDER$BZIP
else
  ui_print " "
  ui_print "   Disabling boot animation..."
fi

if [ $API -ge 27 ]; then
  rm -rf $INSTALLER/system/framework
fi

if [ $API -ge 28 ]; then
  ui_print " "
  ui_print "   Enabling Google's Call Screening..."
  if [ "$SLIM" = false ]; then
    ui_print " "
    ui_print "   Enabling Google's Flip to Shhh..."
    ui_print " "
    # Enabling Google's Flip to Shhh
    WELLBEING_PREF_FILE=$INSTALLER/common/PhenotypePrefs.xml
    chmod 660 $WELLBEING_PREF_FILE
    WELLBEING_PREF_FOLDER=/data/data/com.google.android.apps.wellbeing/shared_prefs/
    mkdir -p $WELLBEING_PREF_FOLDER
    cp -p $WELLBEING_PREF_FILE $WELLBEING_PREF_FOLDER
    if $MAGISK && $BOOTMODE; then
      magiskpolicy --live "create system_server sdcardfs file" "allow system_server sdcardfs file { write }"
      am force-stop "com.google.android.apps.wellbeing"
    fi
  fi
fi

# Adds slim & full variables to service.sh
for i in "SLIM" "FULL"; do
  sed -i "2i $i=$(eval echo \$$i)" $INSTALLER/common/service.sh
done
cp_ch -n $INSTALLER/common/service.sh $UNITY/service.sh
