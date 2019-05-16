#!/system/bin/sh

REMOUNT=true
$MAGISK && ! $SYSOVER && REMOUNT=false

if [ ! "$(grep "#$MODID-UnityIndicator" /init.rc 2>/dev/null)" ]; then
  $REMOUNT && { mount -o rw,remount /system; [ -L /system/vendor ] && mount -o rw,remount /vendor; }
  if [ -f $INFO ]; then
    while read LINE; do
      if [ "$(echo -n $LINE | tail -c 1)" == "~" ] || [ "$(echo -n $LINE | tail -c 9)" == "NORESTORE" ]; then
        continue
      elif [ -f "$LINE~" ]; then
        mv -f $LINE~ $LINE
      else
        rm -f $LINE
        while true; do
          LINE=$(dirname $LINE)
          [ "$(ls -A $LINE 2>/dev/null)" ] && break 1 || rm -rf $LINE
        done
      fi
    done < $INFO
    rm -f $INFO
  fi
  if $MAGISK; then
    if $BOOTMODE; then
      [ -d $MOUNTEDROOT/$MODID/system ] && touch $MOUNTEDROOT/$MODID/remove || rm -rf $MOUNTEDROOT/$MODID
    fi
  fi
  # CUSTOM USER SCRIPT
  rm -f $0
  $REMOUNT && { mount -o ro,remount /system; [ -L /system/vendor ] && mount -o ro,remount /vendor; }
fi
