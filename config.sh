##########################################################################################
#
# Magisk Module Template Config Script
# by topjohnwu
#
##########################################################################################
##########################################################################################
#
# Instructions:
#
# 1. Place your files into system folder (delete the placeholder file)
# 2. Fill in your module's info into module.prop
# 3. Configure the settings in this file (config.sh)
# 4. If you need boot scripts, add them into common/post-fs-data.sh or common/service.sh
# 5. Add your additional or modified system properties into common/system.prop
#
##########################################################################################

##########################################################################################
# Defines
##########################################################################################

# NOTE: This part has to be adjusted to fit your own needs

# Set to true if you need to enable Magic Mount
# Most mods would like it to be enabled
AUTOMOUNT=true

# Set to true if you need to load system.prop
PROPFILE=true

# Set to true if you need post-fs-data script
POSTFSDATA=true

# Set to true if you need late_start service script
LATESTARTSERVICE=true

# Unity Variables
# Uncomment and change 'MINAPI' and 'MAXAPI' to the minimum and maxium android version for your mod (note that magisk has it's own minimum api: 21 (lollipop))
# Uncomment SEPOLICY if you have sepolicy patches in common/sepolicy.sh. Unity will take care of the rest
# Uncomment DYNAMICOREO if you want libs installed to vendor for oreo and newer and system for anything older
# Uncomment DYNAMICAPP if you want anything in $INSTALLER/system/app to be installed to the optimal app directory (/system/priv-app if it exists, /system/app otherwise)
# Uncomment SYSOVERRIDE if you want the mod to always be installed to system (even on magisk)
# Uncomment RAMDISK if you have ramdisk modifications. If you only want ramdisk patching as part of a conditional, just keep this commented out and set RAMDISK=true in that conditional.
# Uncomment DEBUG if you want full debug logs (saved to SDCARD if in twrp, part of regular log if in magisk manager (user will need to save log after flashing)
MINAPI=26
#MAXAPI=25
SEPOLICY=true
#SYSOVERRIDE=true
#DYNAMICOREO=true
#DYNAMICAPP=true
#RAMDISK=true
DEBUG=true

# Custom Variables for Install AND Uninstall - Keep everything within this function
unity_custom() {
  if [ -f $VEN/build.prop ]; then BUILDS="/system/build.prop $VEN/build.prop"; else BUILDS="/system/build.prop"; fi
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
}

# Custom Functions for Install AND Uninstall - You can put them here

##########################################################################################
# Installation Message
##########################################################################################

# Set what you want to show when installing your mod

print_modname() {
  ui_print " "
  ui_print "    *******************************************"
  ui_print "    *<name>*"
  ui_print "    *******************************************"
  ui_print "    *<version>*"
  ui_print "    *<author>*"
  ui_print "    *******************************************"
  ui_print " "
}

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
/system/app/NexusWallpapersStubPrebuilt2017
"

##########################################################################################
# Permissions
##########################################################################################

# NOTE: This part has to be adjusted to fit your own needs

set_permissions() {
  # DEFAULT PERMISSIONS, DON'T REMOVE THEM
  $MAGISK && set_perm_recursive $MODPATH 0 0 0755 0644

  # CUSTOM PERMISSIONS

  # Some templates if you have no idea what to do:
  # Note that all files/folders have the $UNITY prefix - keep this prefix on all of your files/folders
  # Also note the lack of '/' between variables - preceding slashes are already included in the variables
  # Use $SYS for system and $VEN for vendor (Do not use $SYS$VEN, the $VEN is set to proper vendor path already - could be /vendor, /system/vendor, etc.)

  # set_perm_recursive  <dirname>                <owner> <group> <dirpermission> <filepermission> <contexts> (default: u:object_r:system_file:s0)
  # set_perm_recursive $UNITY$SYS/lib 0 0 0755 0644
  # set_perm_recursive $UNITY$VEN/lib/soundfx 0 0 0755 0644

  # set_perm  <filename>                         <owner> <group> <permission> <contexts> (default: u:object_r:system_file:s0)
  # set_perm $UNITY$SYS/lib/libart.so 0 0 0644
}
