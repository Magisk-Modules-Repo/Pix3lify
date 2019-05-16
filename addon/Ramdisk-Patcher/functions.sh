ui_print() { echo -e "ui_print $1\nui_print" >> /proc/self/fd/$OUTFD; }

toupper() {
  echo "$@" | tr '[:lower:]' '[:upper:]'
}

grep_cmdline() {
  local REGEX="s/^$1=//p"
  cat /proc/cmdline | tr '[:space:]' '\n' | sed -n "$REGEX" 2>/dev/null
}

grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

is_mounted() {
  grep -q " `readlink -f $1` " /proc/mounts 2>/dev/null
  return $?
}

abort() {
  ui_print "$1"
  recovery_cleanup
  exit 1
}

setup_flashable() {
  OLD_PATH=$PATH
  BOOTDIR=$TMPDIR/unitytools
  chmod 755 $BOOTDIR/busybox
  $BOOTDIR/busybox --install -s $BOOTDIR
  echo $PATH | grep -q "^$BOOTDIR" || export PATH=$BOOTDIR:$PATH
}

recovery_actions() {
  # Make sure random don't get blocked
  mount -o bind /dev/urandom /dev/random
  # Unset library paths
  OLD_LD_LIB=$LD_LIBRARY_PATH
  OLD_LD_PRE=$LD_PRELOAD
  OLD_LD_CFG=$LD_CONFIG_FILE
  unset LD_LIBRARY_PATH
  unset LD_PRELOAD
  unset LD_CONFIG_FILE
  # Force our own busybox path to be in the front
  # and do not use anything in recovery's sbin
  export PATH=$BOOTDIR:/system/bin:/vendor/bin
}

recovery_cleanup() {
  [ -z $OLD_PATH ] || export PATH=$OLD_PATH
  [ -z $OLD_LD_LIB ] || export LD_LIBRARY_PATH=$OLD_LD_LIB
  [ -z $OLD_LD_PRE ] || export LD_PRELOAD=$OLD_LD_PRE
  [ -z $OLD_LD_CFG ] || export LD_CONFIG_FILE=$OLD_LD_CFG
  umount -l /dev/random 2>/dev/null
}

find_block() {
  for BLOCK in "$@"; do
    DEVICE=`find /dev/block -type l -iname $BLOCK | head -n 1` 2>/dev/null
    if [ ! -z $DEVICE ]; then
      readlink -f $DEVICE
      return 0
    fi
  done
  # Fallback by parsing sysfs uevents
  for uevent in /sys/dev/block/*/uevent; do
    local DEVNAME=`grep_prop DEVNAME $uevent`
    local PARTNAME=`grep_prop PARTNAME $uevent`
    for BLOCK in "$@"; do
      if [ "`toupper $BLOCK`" = "`toupper $PARTNAME`" ]; then
        echo /dev/block/$DEVNAME
        return 0
      fi
    done
  done
  return 1
}

find_boot_image() {
  # Check A/B slot
  SLOT=`grep_cmdline androidboot.slot_suffix`
  if [ -z $SLOT ]; then
    SLOT=`grep_cmdline androidboot.slot`
    [ -z $SLOT ] || SLOT=_${SLOT}
  fi
  [ -z $SLOT ] || ui_print "   Current boot slot: $SLOT"
  
  # Swap the slot
  if [ ! -z $SLOT ]; then [ $SLOT = _a ] && SLOT=_b || SLOT=_a; fi
  
  BOOTIMAGE=
  if [ ! -z $SLOT ]; then
    BOOTIMAGE=`find_block ramdisk$SLOT recovery_ramdisk$SLOT boot$SLOT`
  else
    BOOTIMAGE=`find_block ramdisk recovery_ramdisk kern-a android_boot kernel boot lnx bootimg boot_a`
  fi
  if [ -z $BOOTIMAGE ]; then
    # Lets see what fstabs tells me
    BOOTIMAGE=`grep -v '#' /etc/*fstab* | grep -E '/boot[^a-zA-Z]' | grep -oE '/dev/[a-zA-Z0-9_./-]*' | head -n 1`
  fi
}

flash_image() {
  # Make sure all blocks are writable
  magisk --unlock-blocks 2>/dev/null
  case "$1" in
    *.gz) local COMMAND="magiskboot decompress '$1' - 2>/dev/null";;
    *)    local COMMAND="cat '$1'";;
  esac
  if [ -b "$2" ]; then
    local BLOCK=true
    local img_sz=`stat -c '%s' "$1"`
    local blk_sz=`blockdev --getsize64 "$2"`
    [ $img_sz -gt $blk_sz ] && return 1
  else
    local BLOCK=false
  fi
  if $BOOTSIGNED; then
    ui_print "   Signing boot image"
    eval $COMMAND | $BOOTSIGNER /boot $1 $BOOTDIR/avb/verity.pk8 $BOOTDIR/avb/verity.x509.pem boot-new-signed.img
    ui_print "   Flashing new boot image"
    $BLOCK && dd if=/dev/zero of="$2" 2>/dev/null
    dd if=boot-new-signed.img of="$2"
  elif $BLOCK; then
    ui_print "   Flashing new boot image"
    eval $COMMAND | cat - /dev/zero 2>/dev/null | dd of="$2" bs=4096 2>/dev/null
  else
    ui_print "   Not block device, storing image"
    eval $COMMAND | dd of="$2" bs=4096 2>/dev/null
  fi
  return 0
}

sign_chromeos() {
  ui_print "   Signing ChromeOS boot image"

  echo > empty
  ./chromeos/futility vbutil_kernel --pack new-boot.img.signed \
  --keyblock ./chromeos/kernel.keyblock --signprivate ./chromeos/kernel_data_key.vbprivk \
  --version 1 --vmlinuz new-boot.img --config empty --arch arm --bootloader empty --flags 0x1

  rm -f empty new-boot.img
  mv new-boot.img.signed new-boot.img
}

unpack_ramdisk() {
  find_boot_image
  ui_print " "
  [ -z $BOOTIMAGE ] && abort "   ! Unable to detect target image !"
  ui_print "   Checking boot image signature..."
  BOOTSIGNER="/system/bin/dalvikvm -Xbootclasspath:/system/framework/core-oj.jar:/system/framework/core-libart.jar:/system/framework/conscrypt.jar:/system/framework/bouncycastle.jar -Xnodex2oat -Xnoimage-dex2oat -cp $UF/tools/avb/BootSignature_Android.jar com.android.verity.BootSignature"
  BOOTSIGNED=false; CHROMEOS=false
  mkdir -p $RD
  cd $BOOTDIR
  dd if=$BOOTIMAGE of=boot.img
  eval $BOOTSIGNER -verify boot.img 2>&1 | grep "VALID" && BOOTSIGNED=true
  $BOOTSIGNED && ui_print "   Boot image is signed with AVB 1.0"
  rm -f boot.img  
  magiskinit -x magisk magisk
  ui_print "   Unpacking boot image..."
  magiskboot unpack "$BOOTIMAGE"
  case $? in
    1 ) ui_print "   ! Unable to unpack boot image !"; abort "   ! Aborting !";;
    2 ) ui_print "   ChromeOS boot image detected"; CHROMEOS=true;;
  esac
  # Test patch status
  ui_print "   Checking ramdisk status"
  if [ -e ramdisk.cpio ]; then
    magiskboot cpio ramdisk.cpio test
    STATUS=$?
  else
    # Stock A only system-as-root
    STATUS=0
  fi
  cd ramdisk
  magiskboot cpio ../ramdisk.cpio "extract"
  ui_print " "
}

repack_ramdisk() {
  ui_print "   Repacking ramdisk"
  cd $RD
  find . | cpio -H newc -o > ../ramdisk.cpio
  cd ..
  ui_print "   Repacking boot image"
  if [ $((STATUS & 4)) -ne 0 ]; then
    ui_print "   Compressing ramdisk"
    magiskboot cpio ramdisk.cpio compress
  fi
  magiskboot repack "$BOOTIMAGE" || abort "   ! Unable to repack boot image!"
  $CHROMEOS && sign_chromeos
  flash_image new-boot.img "$BOOTIMAGE" || abort "   ! Insufficient partition size"
  magiskboot cleanup
  rm -f new-boot.img
}

cp_ch() {
  local OPT=`getopt -o inr -- "$@"` BAK=true UBAK=true REST=true BAKFILE=$INFORD FOL=false
  eval set -- "$OPT"
  while true; do
    case "$1" in
      -i) UBAK=false; REST=false; shift;;
      -n) UBAK=false; shift;;
      -r) FOL=true; shift;;
      --) shift; break;;
    esac
  done
  local SRC="$1" DEST="$2" OFILES="$1"
  $FOL && OFILES=$(find $SRC -type f 2>/dev/null)
  [ -z $3 ] && PERM=0644 || PERM=$3
  for OFILE in ${OFILES}; do
    if $FOL; then
      if [ "$(basename $SRC)" == "$(basename $DEST)" ]; then
        local FILE=$(echo $OFILE | sed "s|$SRC|$DEST|")
      else
        local FILE=$(echo $OFILE | sed "s|$SRC|$DEST/$(basename $SRC)|")
      fi
    else
      [ -d "$DEST" ] && local FILE="$DEST/$(basename $SRC)" || local FILE="$DEST"
    fi
    if $BAK; then
      if $UBAK && $REST; then
        [ ! "$(grep "$FILE$" $BAKFILE 2>/dev/null)" ] && echo "$FILE" >> $BAKFILE
        [ -f "$FILE" -a ! -f "$FILE~" ] && { cp -af $FILE $FILE~; echo "$FILE~" >> $BAKFILE; }
      elif ! $UBAK && $REST; then
        [ ! "$(grep "$FILE$" $BAKFILE 2>/dev/null)" ] && echo "$FILE" >> $BAKFILE
      elif ! $UBAK && ! $REST; then
        [ ! "$(grep "$FILE\NORESTORE$" $BAKFILE 2>/dev/null)" ] && echo "$FILE\NORESTORE" >> $BAKFILE
      fi
    fi
    install -D -m $PERM "$OFILE" "$FILE"
  done
}

mount_part() {
  local PART=$1
  local POINT=/${PART}
  [ -L $POINT ] && rm -f $POINT
  mkdir $POINT 2>/dev/null
  is_mounted $POINT && return
  ui_print "   Mounting $PART"
  mount -o rw $POINT 2>/dev/null
  if ! is_mounted $POINT; then
    local BLOCK=`find_block $PART$SLOT`
    mount -o rw $BLOCK $POINT
  fi
  is_mounted $POINT || abort "   ! Cannot mount $POINT"
}

api_level_arch_detect() {
  API=`getprop ro.build.version.sdk`
  ABI=`getprop ro.product.cpu.abi | cut -c-3`
  ABI2=`getprop ro.product.cpu.abi2 | cut -c-3`
  ABILONG=`getprop ro.product.cpu.abi`

  ARCH=arm
  ARCH32=arm
  IS64BIT=false
  if [ "$ABI" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABI2" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
  if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;
}

while [ "$(ps | grep -E 'magisk/addon.d.sh|/addon.d/99-flashaft' | grep -v 'grep')" ]; do
  sleep 1
done
TMPDIR=/dev/unitytmp; BOOTDIR=$TMPDIR/unitytools; RD=$BOOTDIR/ramdisk; OUTFD=
setup_flashable
ui_print " "
ui_print "- Unity Ramdisk Addon Restore"
recovery_actions
unpack_ramdisk
api_level_arch_detect
for i in $TMPDIR/*-unityrd; do
  MODID="$(echo $(basename $i) | sed "s/-unityrd//")"; INFORD="$RD/$MODID-files"
  ui_print "   Restoring $MODID modifications..."
  echo "#$MODID-UnityIndicator" >> $RD/init.rc
  . $i
  [ -d $TMPDIR/$MODID-unityrdfiles ] || continue
  for FILE in $(find $TMPDIR/$MODID-unityrdfiles -type f 2>/dev/null | sed "s|$TMPDIR/$MODID-unityrdfiles|/ramdisk|" 2>/dev/null); do
    cp_ch $TMPDIR/addon/Ramdisk-Patcher$FILE $BOOTDIR$FILE
  done
  [ ! -s $INFORD ] && rm -f $INFORD
done
repack_ramdisk
recovery_cleanup
rm -rf $TMPDIR
# Swap the slot back for other scripts (like magisk)
if [ ! -z $SLOT ]; then [ $SLOT = _a ] && SLOT=_b || SLOT=_a; fi
ui_print "   Done!"
exit 0
