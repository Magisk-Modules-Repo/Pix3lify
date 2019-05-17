##########################################################################################
#
# Unity Config Script
# by topjohnwu, modified by Zackptg5
#
##########################################################################################

##########################################################################################
# Unity Logic - Don't change/move this section
##########################################################################################

if [ -z $UF ]; then
  UF=$TMPDIR/common/unityfiles
  unzip -oq "$ZIPFILE" 'common/unityfiles/util_functions.sh' -d $TMPDIR >&2
  [ -f "$UF/util_functions.sh" ] || { ui_print "! Unable to extract zip file !"; exit 1; }
  . $UF/util_functions.sh
fi

comp_check

##########################################################################################
# Config Flags
##########################################################################################

# Uncomment and change 'MINAPI' and 'MAXAPI' to the minimum and maximum android version for your mod
# Uncomment DYNLIB if you want libs installed to vendor for oreo+ and system for anything older
# Uncomment SYSOVER if you want the mod to always be installed to system (even on magisk) - note that this can still be set to true by the user by adding 'sysover' to the zipname
# Uncomment DIRSEPOL if you want sepolicy patches applied to the boot img directly (not recommended) - THIS REQUIRES THE RAMDISK PATCHER ADDON (this addon requires minimum api of 17)
# Uncomment DEBUG if you want full debug logs (saved to /sdcard in magisk manager and the zip directory in twrp) - note that this can still be set to true by the user by adding 'debug' to the zipname
MINAPI=26
#MAXAPI=25
#DYNLIB=true
#SYSOVER=true
DIRSEPOL=true
DEBUG=true

# Uncomment if you do *NOT* want Magisk to mount any files for you. Most modules would NOT want to set this flag to true
# This is obviously irrelevant for system installs. This will be set to true automatically if your module has no files in system
#SKIPMOUNT=true

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your list in the following format
# This is an example
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here
REPLACE="
"

##########################################################################################
# Custom Logic
##########################################################################################

# Set what you want to display when installing your module

print_modname() {
#  center_and_print # Replace this line if using custom print stuff
  ui_print " "
  ui_print "    *******************************************"
  ui_print "    *               Pix3lify                  *"
  ui_print "    *******************************************"
  ui_print "    *                $VER                     *"
  ui_print "    *      Joey Huab, Aidan Holland, Pika     *" 
  ui_print "    *    John Fawkes, Laster K. (lazerl0rd)   *"
  ui_print "    *******************************************"
  ui_print " "
  unity_main # Don't change this line
}

set_permissions() {
  set_perm $UNITY/system/bin/xmlstarlet 0 2000 0755
  set_perm $UNITY/system/bin/pix3lify 0 2000 0755
  
  [ -f "$UNITY/system/bin/curl" ] && set_perm $UNITY/system/bin/curl 0 2000 0755 

  # Note that all files/folders have the $UNITY prefix - keep this prefix on all of your files/folders
  # Also note the lack of '/' between variables - preceding slashes are already included in the variables
  # Use $VEN for vendor (Do not use /system$VEN, the $VEN is set to proper vendor path already - could be /vendor, /system/vendor, etc.)

  # Some examples:
  
  # For directories (includes files in them):
  # set_perm_recursive  <dirname>                <owner> <group> <dirpermission> <filepermission> <contexts> (default: u:object_r:system_file:s0)
  
  # set_perm_recursive $UNITY/system/lib 0 0 0755 0644
  # set_perm_recursive $UNITY$VEN/lib/soundfx 0 0 0755 0644

  # For files (not in directories taken care of above)
  # set_perm  <filename>                         <owner> <group> <permission> <contexts> (default: u:object_r:system_file:s0)
  
  # set_perm $UNITY/system/lib/libart.so 0 0 0644
}

# Custom Variables for Install AND Uninstall - Keep everything within this function - runs before uninstall/install
unity_custom() {
  if [ -f $VEN/build.prop ]; then BUILDS="/system/build.prop $VEN/build.prop"; else BUILDS="/system/build.prop"; fi
  if [ -d /cache ]; then CACHELOC=/cache; else CACHELOC=/data/cache; fi
  if $BOOTMODE; then
    SDCARD=/storage/emulated/0
  else
    SDCARD=/data/media/0
  fi
  PX1=$(grep -E "ro.vendor.product.device=sailfish|ro.vendor.product.name=sailfish|ro.product.device=sailfish|ro.product.model=Pixel|ro.product.name=sailfish" $BUILDS)
  PX1XL=$(grep -E "ro.vendor.product.device=marlin|ro.vendor.product.name=marlin|ro.product.model=Pixel XL|ro.product.device=marlin|ro.product.name=marlin" $BUILDS)
  PX2=$(grep -E "ro.vendor.product.device=walleye|ro.vendor.product.name=walleye|ro.product.model=Pixel 2|ro.product.name=walleye|ro.product.device=walleye" $BUILDS)
  PX2XL=$(grep -E "ro.vendor.product.name=taimen|ro.vendor.product.device=taimen|ro.product.model=Pixel 2 XL|ro.product.name=taimen|ro.product.device=taimen" $BUILDS)
  PX3=$(grep -E "ro.vendor.product.device=blueline|ro.vendor.product.name=blueline|ro.product.model=Pixel 3|ro.product.name=blueline|ro.product.device=blueline" $BUILDS)
  PX3XL=$(grep -E "ro.vendor.product.device=crosshatch|ro.vendor.product.name=crosshatch|ro.product.model=Pixel 3 XL|ro.product.name=crosshatch|ro.product.device=crosshatch" $BUILDS)
  N5X=$(grep -E "ro.product.device=bullhead|ro.product.name=bullhead" $BUILDS)
  N6P=$(grep -E "ro.product.device=angler|ro.product.name=angler" $BUILDS)
  OOS=$(grep -E "ro.product.manufacturer=OnePlus|ro.product.vendor.brand=OnePlus" $BUILDS)
  MODTITLE=$(echo $(get_file_value $TMPDIR/module.prop "name=") | sed 's|-.*||')
  VER=$(echo $(get_file_value $TMPDIR/module.prop "version=") | sed 's|-.*||')
  AUTHOR=$(echo $(get_file_value $TMPDIR/module.prop "author=") | sed 's|-.*||')
  INSTLOG=$UNITY/Pix3lify-install.log
  MAGISK_VERSIONCODE=$(echo $(get_file_value /data/adb/magisk/util_functions.sh "MAGISK_VERSIONCODE=") | sed 's|-.*||')
}

# Custom Functions for Install AND Uninstall - You can put them here
# Log functions
log_handler() {
	echo "" >> $INSTLOG
	echo -e "$(date +"%m-%d-%Y %H:%M:%S") - $1" >> $INSTLOG 2>&1
}

log_start() {
	if [ -f "$INSTLOG" ]; then
    rm -f $INSTLOG
  fi
  touch $INSTLOG
  echo " " >> $INSTLOG 2>&1
  echo "    *********************************************" >> $INSTLOG 2>&1
  echo "    *          $MODTITLE                        *" >> $INSTLOG 2>&1
  echo "    *********************************************" >> $INSTLOG 2>&1
  echo "    *                 $VER                      *" >> $INSTLOG 2>&1
  echo "    *********************************************" >> $INSTLOG 2>&1
  echo "    *      Joey Huab, Aidan Holland, Pika       *" >> $INSTLOG 2>&1
  echo "    *   John Fawkes, Laster K. (lazerl0rd)      *" >> $INSTLOG 2>&1
  echo "    *********************************************" >> $INSTLOG 2>&1
  echo " " >> $INSTLOG 2>&1
  log_handler "Starting module installation script"
}

# PRINT MOD NAME
log_start

log_print() {
  ui_print "$1"
  log_handler "$1"
}

get_file_value() {
if [ -f "$1" ]; then
cat $1 | grep $2 | sed "s|.*${2}||" | sed 's|"||g'
fi
}
