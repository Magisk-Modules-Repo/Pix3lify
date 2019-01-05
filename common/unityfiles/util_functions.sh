##########################################################################################
#
# Unity (Un)Install Utility Functions
# Adapted from topjohnwu's Magisk General Utility Functions
#
# Magisk util_functions is still used and will override any listed here
# They're present for system installs
#
##########################################################################################

get_outfd() {
  if [ -z $OUTFD ] || readlink /proc/$$/fd/$OUTFD | grep -q /tmp; then
    # We will have to manually find out OUTFD
    for FD in `ls /proc/$$/fd`; do
      if readlink /proc/$$/fd/$FD | grep -q pipe; then
        if ps | grep -v grep | grep -q " 3 $FD "; then
          OUTFD=$FD
          break
        fi
      fi
    done
  fi
}

setup_flashable() {
  OLD_PATH=$PATH
  if [ -x /sbin/.magisk/busybox/busybox ]; then
    # Make sure this path is in the front
    echo $PATH | grep -q '^/sbin/.magisk/busybox' || export PATH=/sbin/.magisk/busybox:$PATH
  elif [ -x /sbin/.core/busybox/busybox ]; then
    # Make sure this path is in the front
    echo $PATH | grep -q '^/sbin/.core/busybox' || export PATH=/sbin/.core/busybox:$PATH
  else
    local BBBIN=$TMPDIR/bin/busybox
    mkdir -p $TMPDIR/bin 2>/dev/null
    cp -f $INSTALLER/common/unityfiles/tools/$ARCH32/busybox $BBBIN 2>/dev/null
    chmod 755 $BBBIN
    $BBBIN --install -s $TMPDIR/bin
    export PATH=$TMPDIR/bin:$PATH
  fi
  # Rerun bootmode detection with proper busybox binaries
  ps | grep zygote | grep -qv grep && BOOTMODE=true || BOOTMODE=false
  $BOOTMODE || ps -A | grep zygote | grep -qv grep && BOOTMODE=true
  # Get Outfd
  get_outfd
}

ui_print() {
  $BOOTMODE && echo "$1" || echo -e "ui_print $1\nui_print" >> /proc/self/fd/$OUTFD
}

toupper() {
  echo "$@" | tr '[:lower:]' '[:upper:]'
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
    for p in "$@"; do
      if [ "`toupper $p`" = "`toupper $PARTNAME`" ]; then
        echo /dev/block/$DEVNAME
        return 0
      fi
    done
  done
  return 1
}

mount_partitions() {
  # Check A/B slot
  SLOT=`grep_cmdline androidboot.slot_suffix`
  if [ -z $SLOT ]; then
    SLOT=_`grep_cmdline androidboot.slot`
    [ $SLOT = "_" ] && SLOT=
  fi
  [ -z $SLOT ] || ui_print "- Current boot slot: $SLOT"
  ui_print "- Mounting /system, /vendor"
  [ -f /system/build.prop ] || is_mounted /system || mount -o rw /system 2>/dev/null
  if ! is_mounted /system && ! [ -f /system/build.prop ]; then
    SYSTEMBLOCK=`find_block system$SLOT`
    mount -t ext4 -o rw $SYSTEMBLOCK /system
  fi
  [ -f /system/build.prop ] || is_mounted /system || abort "! Cannot mount /system"
  grep -qE '/dev/root|/system_root' /proc/mounts && SYSTEM_ROOT=true || SYSTEM_ROOT=false
  if [ -f /system/init ]; then
    SYSTEM_ROOT=true
    mkdir /system_root 2>/dev/null
    mount --move /system /system_root
    mount -o bind /system_root/system /system
  fi
  $SYSTEM_ROOT && { ui_print "- Device using system_root_image"; ROOT=/system_root; }
  if [ -L /system/vendor ]; then
    # Seperate /vendor partition
    is_mounted /vendor || mount -o rw /vendor 2>/dev/null
    if ! is_mounted /vendor; then
      VENDORBLOCK=`find_block vendor$SLOT`
      mount -t ext4 -o rw $VENDORBLOCK /vendor
    fi
    is_mounted /vendor || abort "! Cannot mount /vendor"
  fi
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

find_boot_image() {
  BOOTIMAGE=
  if [ ! -z $SLOT ]; then
    BOOTIMAGE=`find_block boot$SLOT ramdisk$SLOT`
  else
    BOOTIMAGE=`find_block boot ramdisk boot_a kern-a android_boot kernel lnx bootimg`
  fi
  if [ -z $BOOTIMAGE ]; then
    # Lets see what fstabs tells me
    BOOTIMAGE=`grep -v '#' /etc/*fstab* | grep -E '/boot[^a-zA-Z]' | grep -oE '/dev/[a-zA-Z0-9_./-]*' | head -n 1`
  fi
}

flash_boot_image_unity() {
  # Make sure all blocks are writable
  magisk --unlock-blocks 2>/dev/null
  case "$1" in
    *.gz) local COMMAND="magiskboot --decompress '$1' - 2>/dev/null";;
    *)    local COMMAND="cat '$1'";;
  esac
  if [ -b "$2" ]; then
    local BLOCK=true
    local s_size=`stat -c '%s' "$1"`
    local t_size=`blockdev --getsize64 "$2"`
    [ $s_size -gt $t_size ] && return 1
  else
    local BLOCK=false
  fi
  if $BOOTSIGNED; then
    ui_print "- Signing boot image"
    eval $COMMAND | $BOOTSIGNER /boot $1 $INSTALLER/common/unityfiles/tools/avb/verity.pk8 $INSTALLER/common/unityfiles/tools/avb/verity.x509.pem boot-new-signed.img
    ui_print "- Flashing new boot image"
    $BLOCK && dd if=/dev/zero of="$2" 2>/dev/null
    dd if=boot-new-signed.img of="$2"
  elif $BLOCK; then
    ui_print "- Flashing new boot image"
    eval $COMMAND | cat - /dev/zero 2>/dev/null | dd of="$2" bs=4096 2>/dev/null
  else
    ui_print "- Not block device, storing image"
    eval $COMMAND | dd of="$2" bs=4096 2>/dev/null
  fi
  return 0
}

sign_chromeos() {
  ui_print "- Signing ChromeOS boot image"

  echo > empty
  ./chromeos/futility vbutil_kernel --pack new-boot.img.signed \
  --keyblock ./chromeos/kernel.keyblock --signprivate ./chromeos/kernel_data_key.vbprivk \
  --version 1 --vmlinuz new-boot.img --config empty --arch arm --bootloader empty --flags 0x1

  rm -f empty new-boot.img
  mv new-boot.img.signed new-boot.img
}

is_mounted() {
  grep -q " `readlink -f $1` " /proc/mounts 2>/dev/null
  return $?
}

api_level_arch_detect() {
  API=`grep_prop ro.build.version.sdk`
  ABI=`grep_prop ro.product.cpu.abi | cut -c-3`
  ABI2=`grep_prop ro.product.cpu.abi2 | cut -c-3`
  ABILONG=`grep_prop ro.product.cpu.abi`
  ARCH=arm
  ARCH32=arm
  IS64BIT=false
  if [ "$ABI" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABI2" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
  if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;
}

boot_actions_unity() {
  if [ ! -d $MAGISKTMP/mirror/bin ]; then
    mkdir -p $MAGISKTMP/mirror/bin
    mount -o bind $MAGISKBIN $MAGISKTMP/mirror/bin
  fi
  MAGISKBIN=$MAGISKTMP/mirror/bin
}

recovery_actions() {
  # TWRP bug fix
  mount -o bind /dev/urandom /dev/random
  # Temporarily block out all custom recovery binaries/libs
  mv /sbin /sbin_tmp
  # Unset library paths
  OLD_LD_LIB=$LD_LIBRARY_PATH
  OLD_LD_PRE=$LD_PRELOAD
  unset LD_LIBRARY_PATH
  unset LD_PRELOAD
}

recovery_cleanup() {
  mv /sbin_tmp /sbin 2>/dev/null
  [ -z $OLD_PATH ] || export PATH=$OLD_PATH
  [ -z $OLD_LD_LIB ] || export LD_LIBRARY_PATH=$OLD_LD_LIB
  [ -z $OLD_LD_PRE ] || export LD_PRELOAD=$OLD_LD_PRE
  ui_print "- Unmounting partitions"
  [ "$supersuimg" -o -d /su ] && umount /su 2>/dev/null
  umount -l /system_root 2>/dev/null
  umount -l /system 2>/dev/null
  umount -l /vendor 2>/dev/null
  umount -l /dev/random 2>/dev/null
}

abort() {
  ui_print "$1"
  $BOOTMODE || recovery_cleanup
  exit 1
}

set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  [ -z $5 ] && chcon 'u:object_r:system_file:s0' $1 || chcon $5 $1 || return 1
}

set_perm_recursive() {
  find $1 -type d 2>/dev/null | while read dir; do
    set_perm $dir $2 $3 $4 $6
  done
  find $1 -type f -o -type l 2>/dev/null | while read file; do
    set_perm $file $2 $3 $5 $6
  done
}

mktouch() {
  mkdir -p ${1%/*} 2>/dev/null
  [ -z $2 ] && touch $1 || echo $2 > $1
  chmod 644 $1
}

supersuimg_mount() {
  supersuimg=$(ls /cache/su.img /data/su.img 2>/dev/null)
  if [ "$supersuimg" ]; then
    if ! is_mounted /su; then
      ui_print "    Mounting /su..."
      [ -d /su ] || mkdir /su 2>/dev/null
      mount -t ext4 -o rw,noatime $supersuimg /su 2>/dev/null
      for i in 0 1 2 3 4 5 6 7; do
        is_mounted /su && break
        local loop=/dev/block/loop$i
        mknod $loop b 7 $i
        losetup $loop $supersuimg
        mount -t ext4 -o loop $loop /su 2>/dev/null
      done
    fi
  fi
}

require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk $(echo $MINMAGISK | sed -r "s/(.{2})(.{1}).*/v\1.\2+\!/") "
  ui_print "*******************************"
  abort
}

require_new_api() {
  ui_print "***********************************"
  ui_print "!   Your system API of $API isn't"
  if [ "$1" == "minimum" ]; then
    ui_print "! higher than the $1 API of $MINAPI"
    ui_print "! Please upgrade to a newer version"
    ui_print "!  of android with at least API $MINAPI"
  else
    ui_print "!   lower than the $1 API of $MAXAPI"
    ui_print "! Please downgrade to an older version"
    ui_print "!    of android with at most API $MAXAPI"
  fi
  ui_print "***********************************"
  abort
}

cleanup() {
  if $RAMDISK; then
    ui_print "- Repacking ramdisk"
    cd $RD
    find . | cpio -H newc -o > ../ramdisk.cpio
    cd ..
    ui_print "- Repacking boot image"
    magiskboot --repack "$BOOTIMAGE" || abort "! Unable to repack boot image!"
    $CHROMEOS && sign_chromeos
    magiskboot --cleanup
    flash_boot_image_unity new-boot.img "$BOOTIMAGE" || abort "! Insufficient partition size"
    rm -f new-boot.img
    cd /
  fi
  if $MAGISK; then
    unmount_magisk_img
    # Please leave this message in your flashable zip for credits :)
    ui_print " "
    ui_print "    *******************************************"
    ui_print "    *      Powered by Magisk (@topjohnwu)     *"
    ui_print "    *******************************************"
  fi
  $BOOTMODE || recovery_cleanup
  rm -rf $TMPDIR
  ui_print " "
  ui_print "    *******************************************"
  ui_print "    *    Unity by ahrion & zackptg5 @ XDA     *"
  ui_print "    *******************************************"
  ui_print " "
  exit 0
}

device_check() {
  if [ "$(grep_prop ro.product.device)" == "$1" ] || [ "$(grep_prop ro.build.product)" == "$1" ]; then
    return 0
  else
    return 1
  fi
}

cp_ch() {
  #UBAK: false for no backup file creation. REST: false for no file restore on uninstall
  local BAK BAKFILE EXT PERM UBAK=true REST=true
  while [ $# -gt 0 ]; do
    case "$1" in
      -nnp|-pnn) shift; PERM=$1; UBAK=false; REST=false; shift;;
      -np|-pn) shift; PERM=$1; UBAK=false; shift;;
      -nn) shift; UBAK=false; REST=false;;
      -n) shift; UBAK=false;;
      -p) shift; PERM=$1; shift;;
      *) break;;
    esac
  done
  case $2 in
    $RD/*) BAK=true; BAKFILE=$INFORD; EXT="~";;
    $INSTALLER/*|$MOUNTPATH/*|$MAGISKTMP/img/*|$MAGISKBIN/*) BAK=false; BAKFILE=$INFO; EXT=".bak";;
    /system/*|/vendor/*) BAK=true; BAKFILE=$INFO; EXT=".bak";;
    *) BAK=true; BAKFILE=$INFO; EXT=".bak";;
  esac
  [ -z $PERM ] && PERM=0644
  if $BAK && $UBAK && $REST; then
    [ ! "$(grep "$2$" $BAKFILE 2>/dev/null)" ] && echo "$2" >> $BAKFILE
    [ -f "$2" ] && [ ! -f "$2$EXT" ] && { cp -af $2 $2$EXT; echo "$2$EXT" >> $BAKFILE; }
  elif $BAK && ! $UBAK && $REST; then
    [ ! "$(grep "$2$" $BAKFILE 2>/dev/null)" ] && echo "$2" >> $BAKFILE
  elif $BAK && ! $UBAK && ! $REST; then
    [ ! "$(grep "$2NORESTORE$" $BAKFILE 2>/dev/null)" ] && echo "$2NORESTORE" >> $BAKFILE
  fi  
  mkdir -p "$(dirname $2)"
  cp -af "$1" "$2" 2>/dev/null
  chmod $PERM "$2"
  case $2 in
    */vendor/etc/*) chcon u:object_r:vendor_configs_file:s0 $2;;
    */vendor/*.apk) chcon u:object_r:vendor_app_file:s0 $2;;
    */vendor/*) chcon u:object_r:vendor_file:s0 $2;;
    */system/*) chcon u:object_r:system_file:s0 $2;;
  esac
}

patch_script() {
  [ -L /system/vendor ] && local VEN=/vendor
  sed -i -e "s|<ROOT>|\"$ROOT\"|" -e "s|<SYS>|$ROOT/system|" -e "s|<VEN>|$ROOT$VEN|" -e "s|<SHEBANG>|$SHEBANG|" -e "s|<MAGISK>|$MAGISK|" -e "s|<LIBDIR>|$LIBDIR|" -e "s|<SYSOVERRIDE>|$SYSOVERRIDE|" -e "s|<MODID>|$MODID|" -e "s|<INFO>|$(echo $INFO | sed "s|$MOUNTPATH|$MAGISKTMP/img|")|" $1
  if $MAGISK; then sed -i -e "s|\$MOUNTPATH|$MAGISKTMP/img|g" -e "s|\$UNITY|$MAGISKTMP/img/$MODID|g" $1; else sed -i -e "s|\$MOUNTPATH||g" -e "s|\$UNITY||g" $1; fi
}

install_script() {
  if [ "$MAGISKTMP" == "/sbin/.magisk" ]; then
    local INPATH="$NVBASE"
  elif $BOOTMODE; then
    local INPATH="$MOUNTPATH/.core"
  else
    local INPATH="$NVBASE/img/.core"
  fi
  case "$1" in
    -l) shift; INPATH="$INPATH/service.d"; local EXT="-ls";;
    -p) shift; INPATH="$INPATH/post-fs-data.d"; local EXT="";;
    *) INPATH="$INPATH/post-fs-data.d"; local EXT="";;
  esac
  if $MAGISK; then
    case $(basename $1) in
      post-fs-data.sh|service.sh) local INPATH=$MODPATH; cp_ch -n $1 $INPATH/$(basename $1);;
      *) cp_ch -np 0755 $1 $INPATH/$(basename $1);;
    esac
    patch_script $INPATH/$(basename $1)
  else
    cp_ch -np 0700 $1 $MODPATH/$MODID-$(basename $1 | sed 's/.sh$//')$EXT
    patch_script $MODPATH/$MODID-$(basename $1 | sed 's/.sh$//')$EXT
  fi
}

prop_process() {
  sed -i "/^#/d" $1
  if $MAGISK; then
    [ -f $PROP ] || mktouch $PROP
  else
    [ -f $PROP ] || mktouch $PROP "$SHEBANG"
    sed -ri "s|^(.*)=(.*)|setprop \1 \2|g" $1
  fi
  while read LINE; do
    echo "$LINE" >> $PROP
  done < $1
  $MAGISK || chmod 0700 $PROP
}

set_vars() {
  if $BOOTMODE; then MOD_VER="$MAGISKTMP/img/$MODID/module.prop"; $MAGISK && ORIGDIR="$MAGISKTMP/mirror"; else MOD_VER="$MODPATH/module.prop"; ORIGDIR=""; fi
  SYS=/system; VEN=/system/vendor; ORIGVEN=$ORIGDIR/system/vendor; INITD=false; RD=$INSTALLER/common/unityfiles/boot/ramdisk
  ROOTTYPE="MagiskSU"; SHEBANG="#!/system/bin/sh"; UNITY="$MODPATH"; INFO="$MODPATH/$MODID-files"; PROP=$MODPATH/system.prop
  if $DYNAMICOREO && [ $API -ge 26 ]; then LIBPATCH="\/vendor"; LIBDIR=$VEN; else LIBPATCH="\/system"; LIBDIR=/system; fi  
  if ! $MAGISK || $SYSOVERRIDE; then
    UNITY=""
    [ -L /system/vendor ] && { VEN=/vendor; $BOOTMODE && ORIGVEN=$ORIGDIR/vendor; }
    if [ -d /system/addon.d ]; then INFO=/system/addon.d/$MODID-files; else INFO=/system/etc/$MODID-files; fi
    if ! $MAGISK; then
      PROP=$MODPATH/$MODID-props.sh; MOD_VER="/system/etc/$MODID-module.prop"
      # Determine system boot script type
      supersuimg_mount
      ROOTTYPE="other root or rootless"; MODPATH=/system/etc/init.d
      if [ "$supersuimg" ] || [ -d /su ]; then
        SHEBANG="#!/su/bin/sush"; ROOTTYPE="systemless SuperSU"; MODPATH=/su/su.d
      elif [ -e "$(find /data /cache -name supersu_is_here | head -n1)" ]; then
        SHEBANG="#!/su/bin/sush"; ROOTTYPE="systemless SuperSU"
        MODPATH=$(dirname `find /data /cache -name supersu_is_here | head -n1`)/su.d
      elif [ -d /system/su ] || [ -f /system/xbin/daemonsu ] || [ -f /system/xbin/sugote ]; then
        MODPATH=/system/su.d; ROOTTYPE="system SuperSU"
      elif [ -f /system/xbin/su ]; then
        if [ "$(grep "SuperSU" /system/xbin/su)" ]; then
          MODPATH=/system/su.d; ROOTTYPE="system SuperSU"
        else
          ROOTTYPE="LineageOS SU"
        fi
      fi
    fi
  fi
}

initd_message() {
  INITD=true
  ui_print " "
  ui_print "   ! This root method has no boot script support !"
  ui_print "   ! You will need to add init.d support !"
  ui_print " "
}

uninstall_files() {
  local TMP FILE=$1
  [ -z $FILE ] && FILE=$INFO
  if [ "$FILE" == "$INFORD" ]; then
    TMP="~"
  else
    $BOOTMODE && [ -f $MAGISKTMP/img/$MODID/$MODID-files ] && FILE=$MAGISKTMP/img/$MODID/$MODID-files
    TMP=".bak"
    $MAGISK || [ -f $FILE ] || abort "   ! Mod not detected !"
  fi
  if [ -f $FILE ]; then
    while read LINE; do
      if [ "$(echo -n $LINE | tail -c 4)" == ".bak" ] || [ "$(echo -n $LINE | tail -c 1)" == "~" ] || [ "$(echo -n $LINE | tail -c 9)" == "NORESTORE" ]; then
        continue
      elif [ -f "$LINE$TMP" ]; then
        mv -f $LINE$TMP $LINE
      else
        rm -f $LINE
        while true; do
          LINE=$(dirname $LINE)
          if [ "$(ls $LINE)" ]; then
            break 1
          else
            rm -rf $LINE
          fi
        done
      fi
    done < $FILE
    rm -f $FILE
  fi
}

unpack_ramdisk() {
  local PRE POST PATHDIR BOOTDIR=$INSTALLER/common/unityfiles/boot
  if [ "$1" ]; then
    PRE="  "; POST="..."
  else
    PRE="-"; POST=""
  fi
  cp -af $INSTALLER/common/unityfiles/tools/chromeos $BOOTDIR
  chmod -R 0755 $BOOTDIR
  find_boot_image
  ui_print " "
  [ -z $BOOTIMAGE ] && { if [ "$1" != "-s" ]; then
    abort "   ! Unable to detect target image !"
  else
    ui_print "   ! Unable to detect target image !"
    $INITD || initd_message
    return
  fi; }
  ui_print "$PRE Checking boot image signature$POST"
  INFORD="$RD/$MODID-files"
  BOOTSIGNER="/system/bin/dalvikvm -Xbootclasspath:/system/framework/core-oj.jar:/system/framework/core-libart.jar:/system/framework/conscrypt.jar:/system/framework/bouncycastle.jar -Xnodex2oat -Xnoimage-dex2oat -cp $INSTALLER/common/unityfiles/tools/avb/BootSignature_Android.jar com.android.verity.BootSignature"
  RAMDISK=true; BOOTSIGNED=false; CHROMEOS=false
  mkdir -p $RD
  cd $BOOTDIR
  dd if=$BOOTIMAGE of=boot.img
  eval $BOOTSIGNER -verify boot.img 2>&1 | grep "VALID" && BOOTSIGNED=true
  $BOOTSIGNED && ui_print "   Boot image is signed with AVB 1.0"
  rm -f boot.img  
  magiskinit -x magisk magisk
  ui_print "$PRE Unpacking boot image$POST"
  magiskboot --unpack "$BOOTIMAGE"
  case $? in
    1 ) if [ "$1" != "-s" ]; then
          ui_print "   ! Unable to unpack boot image !"; abort "   ! Aborting !"
        else
          ui_print "   ! Unable to parse boot image"; $INITD || initd_message
        fi;;
    2 ) [ "$1" != "-s" ] && { ui_print "   ChromeOS boot image detected"; CHROMEOS=true; };;
    3 ) ui_print "   ! Sony ELF32 format detected !"; abort "   ! Please use BootBridge from @AdrianDC to flash this mod";;
    4 ) if [ "$1" != "-s" ]; then
          ui_print "   ! Sony ELF64 format detected !"; abort "   ! Stock kernel cannot be patched, please use a custom kernel"
        else
          ui_print "   ! Sony ELF64 format detected"; $INITD || initd_message
        fi;;
  esac
  ui_print "$PRE Checking ramdisk status$POST"
  magiskboot --cpio ramdisk.cpio test
  cd ramdisk
  magiskboot --cpio ../ramdisk.cpio "extract"
  cd /
  [ "$1" == "-l" ] && ui_print " "
}

unity_install() {
  ui_print " "
  ui_print "- Installing"

  # Make info file
  rm -f $INFO
  mktouch $INFO

  # Run user install script
  [ -f "$INSTALLER/common/install.sh" ] && . $INSTALLER/common/install.sh
  
  # Addons
  if [ "$(ls -A $INSTALLER/addon 2>/dev/null)" ]; then
    ui_print " "
    ui_print "- Running Addons -"
    for i in $INSTALLER/addon/*/main.sh; do
      [ "$i" == "$INSTALLER/addon/External-Tools/main.sh" ] && continue
      . $i
    done
  fi
  
  # Sepolicy
  if $SEPOLICY; then
    [ "$MODPATH" == "/system/etc/init.d" ] && unpack_ramdisk -s
    if [ "$MODPATH" == "/system/etc/init.d" ] && ! $INITD; then
      ui_print "   Patching sepolicy..."; ui_print " "
    else
      LATESTARTSERVICE=true
      echo -n "supolicy --live" >> $INSTALLER/common/service.sh
    fi
    sed -i -e '/^#.*/d' -e '/^$/d' $INSTALLER/common/sepolicy.sh
    while read LINE; do
      if [ "$MODPATH" == "/system/etc/init.d" ] && ! $INITD; then
        magiskpolicy --load $RD/sepolicy --save $RD/sepolicy "$LINE"
      else
        case $LINE in
          \"*\") echo -n " $LINE" >> $INSTALLER/common/service.sh;;
          \"*) echo -n " $LINE\"" >> $INSTALLER/common/service.sh;;
          *\") echo -n " \"$LINE" >> $INSTALLER/common/service.sh;;
          *) echo -n " \"$LINE\"" >> $INSTALLER/common/service.sh;;
        esac
      fi
    done < $INSTALLER/common/sepolicy.sh
  fi

  # Install scripts
  ui_print "   Installing scripts for $ROOTTYPE..."
  if $MAGISK; then
    # Auto mount
    $AUTOMOUNT && ! $SYSOVERRIDE && mktouch $MODPATH/auto_mount
    # Update info for magisk manager
    if $BOOTMODE; then
      mktouch $MAGISKTMP/img/$MODID/update
      cp_ch -n $INSTALLER/module.prop $MODPATH/module.prop
    fi
  elif [ "$MODPATH" == "/system/etc/init.d" ] && ($POSTFSDATA || $LATESTARTSERVICE || $PROPFILE); then
    initd_message
  fi
  if $MAGISK && $SYSOVERRIDE; then
    cp -f $INSTALLER/common/unityfiles/modidsysover.sh $INSTALLER/common/unityfiles/$MODID-sysover.sh
    sed -i -e "/# CUSTOM USER SCRIPT/ r $INSTALLER/common/uninstall.sh" -e '/# CUSTOM USER SCRIPT/d' $INSTALLER/common/unityfiles/$MODID-sysover.sh
    install_script -p $INSTALLER/common/unityfiles/$MODID-sysover.sh
  elif ! $MAGISK || $SYSOVERRIDE; then
    # Install rom backup script
    if [ -d /system/addon.d ]; then
      ui_print "   Installing addon.d backup script..."
      sed -i "s/<MODID>/$MODID/" $INSTALLER/common/unityfiles/addon.sh
      cp_ch -np 0755 $INSTALLER/common/unityfiles/addon.sh /system/addon.d/$MODID.sh
    else
      ui_print "   ! Addon.d not detected. Backup script not installed..."
    fi
  fi

  # Handle replace folders
  for TARGET in $REPLACE; do
    if $MAGISK; then mktouch $MODPATH$TARGET/.replace; else rm -rf $TARGET; fi
  done

  # Prop files
  $PROPFILE && { prop_process $INSTALLER/common/system.prop; $MAGISK || echo $PROP >> $INFO; }

  # Module info
  cp_ch -n $INSTALLER/module.prop $MOD_VER

  #Install post-fs-data mode scripts
  $POSTFSDATA && install_script -p $INSTALLER/common/post-fs-data.sh

  # Service mode scripts
  $LATESTARTSERVICE && install_script -l $INSTALLER/common/service.sh

  # Install files
  ui_print "   Installing files for $ARCH SDK $API device..."
  rm -f $INSTALLER/system/placeholder $INSTALLER/ramdisk/placeholder
  $IS64BIT || rm -rf $INSTALLER/system/lib64 $INSTALLER/system/vendor/lib64
  for FILE in $(find $INSTALLER/system -type f 2>/dev/null | sed "s|$INSTALLER||" 2>/dev/null); do
    if $DYNAMICAPP; then
      if [ -d /system/priv-app ]; then FILE2=$(echo $FILE | sed 's|/system/app/|/system/priv-app/|'); else FILE2=$(echo $FILE | sed 's|/system/app/.*/|/system/app/|'); fi
    else
      FILE2=$FILE
    fi
    if $DYNAMICOREO && [ $API -ge 26 ]; then
      case $FILE in
        /system/lib*/modules/*) FILE2=$FILE;;
        /system/lib*/*) FILE2=$(echo $FILE | sed "s|/system/|$VEN/|");;
      esac
    fi
    cp_ch $INSTALLER$FILE $UNITY$FILE2
  done
  
  # Add blank line to end of all prop/script files if not already present
  for FILE in $MODPATH/*.sh $MODPATH/*.prop; do
    [ -f $FILE ] && { [ "$(tail -1 $FILE)" ] && echo "" >> $FILE; }
  done

  # Remove info file if not needed
  [ ! -s $INFO ] && rm -f $INFO
  
  # Ramdisk patches
  if $RAMDISK; then
    [ -d "$RD" ] || unpack_ramdisk -l
    # Remove ramdisk mod if exists
    if [ "$(grep "#$MODID-UnityIndicator" $RD/init.rc 2>/dev/null)" ]; then
      ui_print "   ! Mod detected in ramdisk!"
      ui_print "   ! Upgrading mod ramdisk modifications..."
      uninstall_files $INFORD
      sed -i "/#$MODID-UnityIndicator/d" $RD/init.rc
      [ -f "$INSTALLER/common/ramdiskuninstall.sh" ] && . $INSTALLER/common/ramdiskuninstall.sh
    fi
    # Script to remove mod from system/magisk in event mod is only removed from ramdisk (like dirty flashing)
    cp -f $INSTALLER/common/unityfiles/modidramdisk.sh $INSTALLER/common/unityfiles/$MODID-ramdisk.sh
    sed -i -e "/# CUSTOM USER SCRIPT/ r $INSTALLER/common/uninstall.sh" -e '/# CUSTOM USER SCRIPT/d' $INSTALLER/common/unityfiles/$MODID-ramdisk.sh
    install_script -p $INSTALLER/common/unityfiles/$MODID-ramdisk.sh
    # Use comment as install indicator
    echo "#$MODID-UnityIndicator" >> $RD/init.rc
    [ -f "$INSTALLER/common/ramdiskinstall.sh" ] && . $INSTALLER/common/ramdiskinstall.sh
    for FILE in $(find $INSTALLER/ramdisk -type f 2>/dev/null | sed "s|$INSTALLER||" 2>/dev/null); do
      cp_ch $INSTALLER$FILE $INSTALLER/common/unityfiles/boot$FILE
    done
    [ ! -s $INFORD ] && rm -f $INFORD
  fi

  # Set permissions
  ui_print " "
  ui_print "- Setting Permissions"
  set_permissions
}

unity_uninstall() {
  ui_print " "
  ui_print "- Uninstalling"

  # Remove files
  uninstall_files

  $MAGISK && { rm -rf $MODPATH $MAGISKTMP/img/$MODID; rm -f $NVBASE/post-fs-data.d/$MODID-sysover.sh; }

  # Run user install script
  [ -f "$INSTALLER/common/uninstall.sh" ] && . $INSTALLER/common/uninstall.sh
  
  # Ramdisk patches
  if $RAMDISK; then
    [ -d "$RD" ] || unpack_ramdisk -l
    uninstall_files $INFORD
    sed -i "/#$MODID-UnityIndicator/d" $RD/init.rc
    [ -f "$INSTALLER/common/ramdiskuninstall.sh" ] && . $INSTALLER/common/ramdiskuninstall.sh
  fi

  ui_print " "
  ui_print "- Completing uninstall -"
}

##########################################################################################
# MAIN
##########################################################################################

# Temp installer paths and vars
MOUNTPATH=$TMPDIR/magisk_img; SYSOVERRIDE=false; DEBUG=false; DYNAMICOREO=false; DYNAMICAPP=false; RAMDISK=false; SEPOLICY=false
OIFS=$IFS; IFS=\|; 
case $(echo $(basename $ZIP) | tr '[:upper:]' '[:lower:]') in
  *debug*) DEBUG=true;;
  *sysover*) SYSOVERRIDE=true;;
esac
IFS=$OIFS

# Preliminary detection of bootmode
ps | grep zygote | grep -qv grep >/dev/null && export BOOTMODE=true || export BOOTMODE=false
$BOOTMODE || ps -A 2>/dev/null | grep zygote | grep -qv grep >/dev/null && export BOOTMODE=true

# Setup busybox and stuff
setup_flashable

# Unzip files
ui_print " "
ui_print "Unzipping files..."
unzip -oq "$ZIP" -d $INSTALLER 2>/dev/null
[ -f "$INSTALLER/config.sh" ] || abort "! Unable to extract zip file!"
[ "$(grep_prop id $INSTALLER/module.prop)" == "UnityTemplate" ] && { ui_print "! Unity Template is not a separate module !"; abort "! This template is for devs only !"; }

# Insert module info into config.sh and run it
(
for TMP in version name author; do
  NEW=$(grep_prop $TMP $INSTALLER/module.prop)
  [ "$TMP" == "author" ] && NEW="by ${NEW}"
  CHARS=$((${#NEW}-$(echo "$NEW" | tr -cd "©®™" | wc -m)))
  SPACES=""
  if [ $CHARS -le 41 ]; then
    for i in $(seq $(((41-$CHARS) / 2))); do
      SPACES="${SPACES} "
    done
  fi
  if [ $(((41-$CHARS) % 2)) -eq 1 ]; then sed -i "s/<$TMP>/$SPACES$NEW${SPACES} /" $INSTALLER/config.sh; else sed -i "s/<$TMP>/$SPACES$NEW$SPACES/" $INSTALLER/config.sh; fi
done
)
. $INSTALLER/config.sh

[ -z $MODID ] && MODID=`grep_prop id $INSTALLER/module.prop`
MODPATH=$MOUNTPATH/$MODID
MINMAGISK=$(grep_prop minMagisk $INSTALLER/module.prop)

# Print modname
print_modname

# Mount data and cache
ui_print "- Mounting /data, /cache"
is_mounted /data || mount /data || is_mounted /cache || mount /cache || { ui_print "! Unable to mount partitions"; exit 1; }

# Determine magisk path if applicable
if [ -f /data/adb/magisk/util_functions.sh ]; then
  NVBASE=/data/adb
elif [ -f /data/magisk/util_functions.sh ]; then
  NVBASE=/data
fi
[ -z $NVBASE ] || MAGISKBIN=$NVBASE/magisk

# Determine install type
if [ -z $MAGISKBIN ]; then
  MAGISK=false
  ui_print "- System install detected"
else
  MAGISK=true
  ui_print "- Magisk install detected"
  cp -f $MAGISKBIN/util_functions.sh $INSTALLER/common/unityfiles/util_functions_mag.sh
  if $SYSOVERRIDE; then
    ui_print "- Overriding paths for system install"
    $BOOTMODE && { ui_print "   ! Magisk manager isn't supported!"; abort "   ! Install in recovery !"; }
    sed -i "s/-o ro/-o rw/g" $INSTALLER/common/unityfiles/util_functions_mag.sh
  fi
  . $INSTALLER/common/unityfiles/util_functions_mag.sh
  [ ! -z $MAGISK_VER_CODE -a $MAGISK_VER_CODE -ge $MINMAGISK ] || require_new_magisk
  if [ $MAGISK_VER_CODE -ge 18000 ]; then MAGISKTMP=/sbin/.magisk; else MAGISKTMP=/sbin/.core; fi
fi

# Mount partitions and detect version/architecture
mount_partitions
api_level_arch_detect

# Check for min & max api version
[ -z $MINAPI ] && MINAPI=21
[ $API -lt $MINAPI ] && require_new_api 'minimum'
[ -z $MAXAPI ] || { [ $API -gt $MAXAPI ] && require_new_api 'maximum'; }

# Set variables
set_vars

if $MAGISK; then
  if $BOOTMODE; then
    IMG=$NVBASE/magisk_merge.img
    boot_actions_unity
  else
    IMG=$NVBASE/magisk.img
    recovery_actions
  fi
  request_zip_size_check "$ZIP"
  mount_magisk_img
else
  recovery_actions
fi

# Insert modid and mustom user script into mod script
for i in "post-fs-data.sh" "service.sh"; do
  cp -f $INSTALLER/common/unityfiles/modid.sh $INSTALLER/common/unityfiles/$i
  sed -i -e "s/<MODID>/$MODID/" -e "/# CUSTOM USER SCRIPT/ r $INSTALLER/common/$i" -e '/# CUSTOM USER SCRIPT/d' $INSTALLER/common/unityfiles/$i
  mv -f $INSTALLER/common/unityfiles/$i $INSTALLER/common/$i
done

# Add blank line to end of all files if needbe
for FILE in $INSTALLER/common/*.sh $INSTALLER/common/*.prop; do
  [ "$(tail -1 $FILE)" ] && echo "" >> $FILE
done

# Import user tools
[ -f "$INSTALLER/addon.tar.gz" ] && tar -xf $INSTALLER/addon.tar.xz -C $INSTALLER 2>/dev/null
[ -f "$INSTALLER/addon/External-Tools/main.sh" ] && . $INSTALLER/addon/External-Tools/main.sh

# Unpack ramdisk
$RAMDISK && unpack_ramdisk

#Debug
if $DEBUG; then
  ui_print " "
  ui_print "- Debug mode"
  ui_print "  Debug log will be written to: /sdcard/$MODID-debug.log"
  if $BOOTMODE; then
    exec > >(tee -a /storage/emulated/0/$MODID-debug.log ); exec 2>/storage/emulated/0/$MODID-debug.log
  else
    exec > >(tee -a /data/media/0/$MODID-debug.log ); exec 2>/data/media/0/$MODID-debug.log
  fi
  set -x
fi

# Load user vars/function
unity_custom
$RAMDISK && [ ! -d "$RD" ] && unpack_ramdisk -l

# Determine mod installation status
if $RAMDISK && [ "$(grep "#$MODID-UnityIndicator" $RD/init.rc 2>/dev/null)" ] && [ ! -f "$MOD_VER" ]; then
  ui_print " "
  ui_print "  ! Mod present in ramdisk but not in system!"
  ui_print "  ! Ramdisk modifications will be uninstalled!"
  rm -f $INSTALLER/common/uninstall.sh
  unity_uninstall
elif $MAGISK && ! $SYSOVERRIDE && [ -f "/system/addon.d/$MODID-files" -o -f "/system/etc/$MODID-files" ]; then
  ui_print " "
  ui_print "  ! Previous system override install detected!"
  ui_print "  ! Removing...!"
  $BOOTMODE && { ui_print "  ! Magisk manager isn't supported!"; abort "   ! Flash in TWRP !"; }
  mount -o rw,remount /system
  [ -L /system/vendor ] && mount -o rw,remount /vendor
  if [ -d /system/addon.d ]; then INFO=/system/addon.d/$MODID-files; else INFO=/system/etc/$MODID-files; fi
  unity_uninstall
  INFO="$MODPATH/$MODID-files"
  unity_install
elif [ -f "$MOD_VER" ]; then
  if $RAMDISK && [ ! "$(grep "#$MODID-UnityIndicator" $RD/init.rc 2>/dev/null)" ]; then
    ui_print " "
    ui_print "  ! Mod present in system but not in ramdisk!"
    ui_print "  ! Running upgrade..."
    RAMDISK=false; unity_uninstall
    RAMDISK=true; unity_install
  elif [ $(grep_prop versionCode $MOD_VER) -ge $(grep_prop versionCode $INSTALLER/module.prop) ]; then
    ui_print " "
    ui_print "  ! Current or newer version detected!"
    unity_uninstall
  else
    ui_print " "
    ui_print "  ! Older version detected! Upgrading..."
    unity_uninstall
    unity_install
  fi
else
  unity_install
fi

# Complete (un)install
cleanup
