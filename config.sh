##########################################################################################
#
# Unity Config Script
# by topjohnwu, modified by Zackptg5
#
##########################################################################################

##########################################################################################
# Installation Message - Don't change this
##########################################################################################

print_modname() {
  ui_print " "
  ui_print "    *******************************************"
  ui_print "    *<name>*"
  ui_print "    *******************************************"
  ui_print "    *<version>*"
  ui_print "    *    Joey Huab, Aidan Holland, Pika       *" 
  ui_print "    *    John Fawkes, Laster K. (lazerl0rd)   *"
  ui_print "    *******************************************"
  ui_print " "
}

##########################################################################################
# Defines
##########################################################################################

# Uncomment and change 'MINAPI' and 'MAXAPI' to the minimum and maxium android version for your mod (note that unity's minapi is 21 (lollipop) due to bash)
# Uncomment DYNAMICOREO if you want libs installed to vendor for oreo+ and system for anything older
# Uncomment SYSOVERRIDE if you want the mod to always be installed to system (even on magisk) - note that this can still be set to true by the user by adding 'sysover' to the zipname
# Uncomment DEBUG if you want full debug logs (saved to /sdcard in magisk manager and the zip directory in twrp) - note that this can still be set to true by the user by adding 'debug' to the zipname
MINAPI=26
#MAXAPI=25
#DYNAMICOREO=true
#SYSOVERRIDE=true
DEBUG=true

# Things that ONLY run during an upgrade (occurs after unity_custom) - you probably won't need this
# A use for this would be to back up app data before it's wiped if your module includes an app
# NOTE: the normal upgrade process is just an uninstall followed by an install
unity_upgrade() {
  : # Remove this if adding to this function
}

# Custom Variables for Install AND Uninstall - Keep everything within this function - runs before uninstall/install
unity_custom() {
  if [ -f $VEN/build.prop ]; then BUILDS="/system/build.prop $VEN/build.prop"; else BUILDS="/system/build.prop"; fi
  if [ -d /cache ]; then CACHELOC=/cache; else CACHELOC=/data/cache; fi
  BIN=$SYS/bin
  XBIN=$SYS/xbin
  if [ -d $XBIN ]; then BINPATH=$XBIN; else BINPATH=$BIN; fi
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
  MANUFACTURER=$(grep "ro.product.manufacturer" $BUILDS)
  if [ "$MANUFACTURER" == "HTC" ]; then
    BFOLDER="/system/customize/resource/"
    BZIP="hTC_bootup.zip"
  else
    BFOLDER="/system/media/"
    BZIP="bootanimation.zip"
  fi
  MODTITLE=$(grep_prop name $INSTALLER/module.prop)
  VER=$(grep_prop version $INSTALLER/module.prop)
  AUTHOR=$(grep_prop author $INSTALLER/module.prop)
  INSTLOG=$CACHELOC/Pix3lify-install.log
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

# Custom Functions for Install AND Uninstall - You can put them here


##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# By default Magisk will merge your files with the original system
# Directories listed here however, will be directly mounted to the correspond directory in the system

# You don't need to remove the example below, these values will be overwritten by your own list
# This is an example
REPLACE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here, it will overwrite the example
# !DO NOT! remove this if you don't need to replace anything, leave it empty as it is now
REPLACE="
"

##########################################################################################
# Custom Permissions
##########################################################################################

set_permissions() {
  set_perm $UNITY/system/bin/xmlstarlet 0 2000 0755
  set_perm $UNITY$BINPATH/pix3lify 0 2000 0755
  
  [ -f "$UNITY$BINPATH/curl" ] && set_perm $UNITY$BINPATH/curl 0 2000 0755 

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