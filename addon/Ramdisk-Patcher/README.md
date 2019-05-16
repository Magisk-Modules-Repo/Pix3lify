# Ramdisk Patcher - Addon for ramdisk patching

## Instructions:
* Place ramdisk files into the ramdisk folder
* Add install and uninstall logic to ramdiskinstall and ramdiskuninstall respectively (note this should be for boot img patching ONLY)
* Don't touch anything else

## Usable variables:
* RD: ramdisk directory - any modification of the actual ramdisk occurs here
* MODID
* Any variable from api function (API, ABILONG, ABI, ABI2, ARCH, ARCH32, IS64BIT)

## Usable functions:
* ui_print
* grep_prop
* is_mounted
* mount_part
* cp_ch (for ramdisk stuff only)

## Included Binaries/Credits:
* magiskboot and magiskinit/magiskpolicy by [topjohnwu @github](https://github.com/topjohnwu)
