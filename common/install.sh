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

ui_print "   Decompressing files..."
tar -xf $INSTALLER/custom.tar.xz -C $INSTALLER 2>/dev/null

# GET LAUNCHER FROM ZIP NAME
case $(basename $ZIP) in
  *customized*|*Customized*|*CUSTOMIZED*) LAUNCHER=customized;;
  *pixel*|*Pixel*|*PIXEL*) LAUNCHER=pixel;;
  *rootless*|*Rootless*|*ROOTLESS*) LAUNCHER=rootless;;
  *ruthless*|*Ruthless*|*RUTHLESS*) LAUNCHER=ruthless;;
esac
# GET USERAPP FROM ZIP NAME
case $(basename $ZIP) in
  *UAPP*|*Uapp*|*uapp*) UA=true;;
  *SAPP*|*Sapp*|*sapp*) UA=false;;
esac

# Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
KEYCHECK=$INSTALLER/common/keycheck
chmod 755 $KEYCHECK

ui_print " "
ui_print "   Removing remnants from past pix3lify installs..."
# Uninstall existing pix3lify installs
OVERLAY='/data/resource-cache/overlays.list'
if [ -f "$OVERLAY" ] ;then
  ui_print "   Removing $OVERLAY"
  rm -f "$OVERLAY"
fi

ui_print " "
if [ -z $LAUNCHER ] || [ -z $UA ]; then
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
  if [ -z $LAUNCHER ]; then
	ui_print " "
	ui_print "- Do you want to install a launcher? (note: if you encounter a force close, reinstall and choose Vol-)"
	ui_print "   Vol+ = Install a launcher"
	ui_print "   Vol- = Do NOT install a launcher"
	if $FUNCTION; then
	  ui_print " "
	  ui_print " - Select Launcher -"
	  ui_print "   Choose which Pixel Launcher you want installed:"
	  ui_print "   Vol+ = Stock Pixel Launcher (Android 9+ only), Vol- = Other Launcher choices"
	  if $FUNCTION; then
	    ui_print " "
	    ui_print "   Installing Stock Pixel Launcher..."
	    LAUNCHER=pixel
	  else
	    ui_print " "
	    ui_print " - Select Custom launcher -"
        ui_print "   Choose which custom launcher you want installed:"
        ui_print "   Vol+ = Customized Pixel Launcher, Vol- = Ruthless/Rootless"
        if $FUNCTION; then
          ui_print " "
          ui_print "   Installing Customized Pixel Launcher..."
          LAUNCHER=customized
        else
          ui_print " "
          ui_print " - Select Custom Launcher -"
          ui_print "   Choose which custom Launcher you want installed:"
          ui_print "   Vol+ = Ruthless launcher, Vol- = Rootless launcher"
          if $FUNCTION; then
            ui_print " "
            ui_print "   Installing Ruthless Launcher..."
            LAUNCHER=ruthless
          else
            ui_print " "
            ui_print "   Installing Rootless	 Launcher..."
            LAUNCHER=rootless
          fi
        fi
    fi
  else
    ui_print "   Skip installing launchers..."
  fi
  if [ -z $UA ]; then
    ui_print " "
    ui_print " - Select App Location -"
    ui_print "   Choose how you want the launcher to be installed"
    ui_print "   Note that it can get killed off by system"
    ui_print "    if installed as a user app:"
    ui_print "   Vol+ = system app (recommended), Vol- = user app"
    if $FUNCTION; then
      UA=false
    else
      UA=true
    fi
  else
    ui_print "   Launcher install method specified in zipname!"
  fi
else
  ui_print "   Options specified in zipname!"
fi

ui_print " "
if $UA; then
  if $MAGISK; then
    ui_print "   Launcher will be installed as user app"
    cp -f $INSTALLER/custom/$LAUNCHER/PixelLauncher.apk $UNITY/PixelLauncher.apk
  else
    cp -f $INSTALLER/custom/$LAUNCHER/PixelLauncher.apk $SDCARD/PixelLauncher.apk
    ui_print " "
    ui_print "   PixelLauncher.apk copied to root of internal storage (sdcard)"
    ui_print "   Install manually after booting"
    sleep 2
  fi
  rm -rf $INSTALLER/system/app
else
  ui_print "   Launcher will be installed as system app"
  cp -f $INSTALLER/custom/$LAUNCHER/PixelLauncher.apk $INSTALLER/system/app/PixelLauncher/PixelLauncher.apk
fi