if $MAGISK; then
  ui_print "   Note that to remove any ramdisk changes,"
  ui_print "   you will need to flash this zip again"
  ui_print " "
  ui_print "   Removing mod in magisk manager won't remove ramdisk changes"
  sleep 2
fi

rm -f $TMPDIR/addon/Ramdisk-Patcher/ramdisk/placeholder
sed -i -e '/^#.*/d' -e '/^$/d' $TMPDIR/addon/Ramdisk-Patcher/ramdiskinstall.sh

# Only run if needed
if ! $DIRSEPOL && [ ! "$(ls -A $TMPDIR/addon/Ramdisk-Patcher/ramdisk 2/dev/null)" ] && [ ! -s $TMPDIR/addon/Ramdisk-Patcher/ramdiskinstall.sh ]; then
  rm -rf $TMPDIR/addon/Ramdisk-Patcher
  exit 0
fi

# Remove ramdisk mod if exists
if [ "$(grep "#$MODID-UnityIndicator" $RD/init.rc 2>/dev/null)" ]; then
  ui_print " "
  ui_print "   ! Mod detected in ramdisk!"
  ui_print "   ! Upgrading mod ramdisk modifications..."
  uninstall_files $INFORD
  sed -i "/#$MODID-UnityIndicator/d" $RD/init.rc
  . $TMPDIR/addon/Ramdisk-Patcher/ramdiskuninstall.sh
fi

# Direct sepolicy patching if applicable
if $DIRSEPOL && [ -s $TMPDIR/common/sepolicy.sh ]; then
  ui_print " "
  ui_print "   Applying sepolicy patches directly to ramdisk..."
  sed -i -e '/^#.*/d' -e '/^$/d' $TMPDIR/common/sepolicy.sh
  echo -n 'magiskpolicy --load $RD/sepolicy --save $RD/sepolicy' > $TMPDIR/addon/Ramdisk-Patcher/tmp
  while read LINE; do
    case $LINE in
      \"*\") echo -n " $LINE" >> $TMPDIR/addon/Ramdisk-Patcher/tmp;;
      \"*) echo -n " $LINE\"" >> $TMPDIR/addon/Ramdisk-Patcher/tmp;;
      *\") echo -n " \"$LINE" >> $TMPDIR/addon/Ramdisk-Patcher/tmp;;
      *) echo -n " \"$LINE\"" >> $TMPDIR/addon/Ramdisk-Patcher/tmp;;
    esac
  done < $TMPDIR/common/sepolicy.sh
  chmod 0755 $TMPDIR/addon/Ramdisk-Patcher/tmp
  . $TMPDIR/addon/Ramdisk-Patcher/tmp
fi

# Use comment as install indicator
echo "#$MODID-UnityIndicator" >> $RD/init.rc
. $TMPDIR/addon/Ramdisk-Patcher/ramdiskinstall.sh
for FILE in $(find $TMPDIR/addon/Ramdisk-Patcher/ramdisk -type f 2>/dev/null | sed "s|$TMPDIR/addon/Ramdisk-Patcher||" 2>/dev/null); do
  cp_ch $TMPDIR/addon/Ramdisk-Patcher$FILE $BOOTDIR$FILE
done
[ ! -s $INFORD ] && rm -f $INFORD

# Use addon.d if available, else add script to remove mod from system/magisk in event mod is only removed from ramdisk (like dirty flashing)
if [ -d /system/addon.d ]; then
  $MAGISK && ! $SYSOVER && mount -o rw,remount /system
  # Copy needed binaries
  mkdir /system/addon.d/unitytools 2>/dev/null
  cp -rf $TMPDIR/addon/Ramdisk-Patcher/tools/chromeos $TMPDIR/addon/Ramdisk-Patcher/tools/avb /system/addon.d/unitytools
  cp -f $TMPDIR/common/unityfiles/tools/$ARCH32/* /system/addon.d/unitytools/
  # Copy ramdisk modifications
  [ "$(ls -A $TMPDIR/addon/Ramdisk-Patcher/ramdisk 2>/dev/null)" ] && cp_ch -rn $TMPDIR/addon/Ramdisk-Patcher/ramdisk /system/addon.d/$MODID-unityrdfiles
  # Place mod script
  [ -s $TMPDIR/addon/Ramdisk-Patcher/ramdiskinstall.sh ] && sed -i "1i #!/system/bin/sh\nMODID=$MODID" $TMPDIR/addon/Ramdisk-Patcher/ramdiskinstall.sh || echo -e "#!/system/bin/sh\nMODID=$MODID" > $TMPDIR/addon/Ramdisk-Patcher/ramdiskinstall.sh
  [ -f "$TMPDIR/addon/Ramdisk-Patcher/tmp" ] && sed -i "2r $TMPDIR/addon/Ramdisk-Patcher/tmp" $TMPDIR/addon/Ramdisk-Patcher/ramdiskinstall.sh
  [ "$(tail -1 "$TMPDIR/addon/Ramdisk-Patcher/ramdiskinstall.sh")" ] && echo "" >> $TMPDIR/addon/Ramdisk-Patcher/ramdiskinstall.sh
  cp_ch -n $TMPDIR/addon/Ramdisk-Patcher/ramdiskinstall.sh /system/addon.d/$MODID-unityrd 0755
  # Place master Unity script  
  cp_ch -i $TMPDIR/addon/Ramdisk-Patcher/addon.sh /system/addon.d/99-unityrd.sh 0755
  cp_ch -i $TMPDIR/addon/Ramdisk-Patcher/functions.sh /system/addon.d/unitytools/functions 0755
  $MAGISK && ! $SYSOVER && mount -o ro,remount /system
else
  sed -i -e "/# CUSTOM USER SCRIPT/ r $TMPDIR/common/uninstall.sh" -e '/# CUSTOM USER SCRIPT/d' $TMPDIR/addon/Ramdisk-Patcher/noaddon.sh
  mv -f $TMPDIR/addon/Ramdisk-Patcher/noaddon.sh $TMPDIR/addon/Ramdisk-Patcher/$MODID-ramdisk.sh
  install_script -p $TMPDIR/addon/Ramdisk-Patcher/$MODID-ramdisk.sh
fi
