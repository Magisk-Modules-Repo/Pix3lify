uninstall_files $INFORD
if $DIRSEPOL || [ -f /system/addon.d/$MODID-unityrd ]; then
  $MAGISK && ! $SYSOVER && { mount -o rw,remount /system; [ -L /system/vendor ] && mount -o rw,remount /vendor; }
  rm -f /system/addon.d/$MODID-unityrd
  $MAGISK && ! $SYSOVER && { mount -o ro,remount /system; [ -L /system/vendor ] && mount -o ro,remount /vendor; }
fi
sed -i "/#$MODID-UnityIndicator/d" $RD/init.rc
. $TMPDIR/addon/Ramdisk-Patcher/ramdiskuninstall.sh
