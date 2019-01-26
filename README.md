<p align="center">
  <img src="https://raw.githubusercontent.com/Magisk-Modules-Repo/Pix3lify/master/.github/logo.png">
</p>

<p align="center">
 <a href="https://forum.xda-developers.com/apps/magisk/module-pixel-2-experience-t3757137"><img src="https://img.shields.io/badge/XDA-Thread-orange.svg"></a><br /><a href="https://t.me/PIX3LIFY"><img src="https://img.shields.io/badge/Telegram-Channel-blue.svg"></a><br /><a href="https://discord.gg/sUyZdSv"><img src="https://img.shields.io/discord/529370157563510814.svg"></a>
</p>

## ⭐ Module description

As a Mi A1 user, I was stuck with Stock Oreo 8.0.0 without Oreo custom ROMs when I first bought my device. Kernel sources weren't released at the time so I decided if I can cook up a Magisk module that can bring me the Pixel UI without the need to install that ROM. What I did is to search around the internet which lead me to download the Pixel 3 XL factory images and extract the files mostly needed in the new Pixel 3 devices. I've decided to gather these files and compiled them all into a single Magisk Module. This module can be flashed with other devices on Oreo and above as well.

## ⭐ Compatibility

-   [![Magisk](https://img.shields.io/badge/Magisk-17%2B-00B39B.svg)](https://forum.xda-developers.com/apps/magisk/official-magisk-v7-universal-systemless-t3473445)
-   [![Android Oreo+](https://img.shields.io/badge/Oreo-8.0+-blue.svg)](https://www.android.com/versions/oreo-8-0/)
-   Close to Stock/AOSP ROMs (not for MIUI, TouchWiz, EMUI, OOS, etc.)
-   All root solutions (requires init.d support if not using Magisk or supersu. Try [Init.d Injector](https://forum.xda-developers.com/android/software-hacking/mod-universal-init-d-injector-wip-t3692105))
-   Pixel, Nexus, and OxygenOS devices are not compatible and were leading to bootloops. The module will now warn about this and give the option to abort or bypass warning and install anyway(to uninstall if in bootloop, boot to twrp and flash zip).

## ⭐ Reminders

-   TO COMPLETELY UNINSTALL THE MODULE AND AVOID BOOTLOOPS, INSTALL THE ZIP AGAIN IN MAGISK OR TWRP!!
-   Take a full backup before installing the module.
-   Please send Pix3lify debug file from internal storage or logcat if any issues/bugs occur.

## ⭐ Users without working volume keys

-   To choose options without using volume keys, you can rename the zip
-   Currently the choices are FULL, SLIM, OVER, and BOOT.
-   FULL = The full module not including overlay/accent and boot animation
-   SLIM = No additional apps, wellbeing scripts, fonts, sounds, and all overlays except pix3lify.
-   OVER = Install pixel overlays
-   ACC = Install pixel accent
-   BOOT = Install pixel boot animation
-   To use the basename zip feature all you need to do is add the options to the zipname and only flash the zip in recovery. Magisk renames all zips to install.zip so flashing in magisk manager will NOT work. Heres an example of using basename to install full and overlays ( Pix3lify-2.6-full-over.zip )
-   The options can either be full, Full, or FULL ( applies to all options )

## ⭐ Features

-   Pixel Blue theme accent
-   Adds Daydream VR support
-   Adds Digital Wellbeing in Settings app
-   Adds Gestures in Settings app (device dependent)
-   Adds Pixel alarms/media/ringtones/UI sounds
-   Adds Pixel Stand app (wireless charging stand)
-   Adds Pixel Sounds app ([mileage may vary](https://github.com/Magisk-Modules-Repo/Pix3lify/wiki/Sounds))
-   Adds Google Markup app (mileage may vary)
-   Adds Pixel exclusive wallpapers
-   Enables Google Dialer install via Playstore
-   Enables Google Dialer's Call Screening ([mileage may vary](https://github.com/Magisk-Modules-Repo/Pix3lify/wiki/Call-Screening))
-   Enables Camera2 API support (find a working Modded Google Camera app [here](https://www.celsoazevedo.com/files/android/google-camera/))
-   Enables EIS support (device dependent)
-   Enables Google Assistant
-   Enables Night Light (device dependent)

## ⭐ Features Under Development

-   Flip to Shhh (mileage may vary)

## ⭐ Changelog

### v2.9

-   Remove unneed fonts
-   Fix emoji
-   Add curl binary
-   Add Google perms

### v2.7-8

-   Hot Fixes

### v2.6

-   BIG UPDATE!
-   Add more fonts
-   Update Unity fixes
-   Introduce logging
-   Add pix3lify terminal script to send logs
-   Bug fixes/typos
-   Unity 3.3
-   Added xmlstarlet for xml patching
-   Bug fixes/typos
-   Add (FULL) or (SLIM) to module.prop depending on user choice
-   Magisk backwards compatibility

### v2.5.2

-   Even more hotfixes

### v2.5.1

-   Hotfixes

### v2.5

-   Rewrote install script to add more customization options
-   Added basename zip for users without working volume keys
-   Add Pixel boot animation option

### v2.4.2

-   Warnings for devices running OxygenOS
-   Ignore warnings options
-   Refactor the installation script
-   Fixed keycheck
-   Added sepolicy statements
-   Various bug fixes

### v2.4.1

-   Expanded the list of unsupported devices to the Nexuses
-   Cleaned the installation script
-   Added an option to install without the Pixel accent

### v2.4

-   Abort installation on Pixel devices
-   Enable Debug feature

### v2.3

-   Enable Google Dialer install via Playstore (for before and after Oreo)
-   Enables Call Screening even if you install after Pix3lify (reboot after install)
-   Fixes the overlay removal bugs

### v2.2.1

-   Fixes Sounds
-   Enables Call Screening's Post Call survey
-   Fixes the uninstallation bugs
-   Made the overlays optional

### v2.2

-   Remove launcher choices (please install from Play Store instead)

### v2.1.2

-   Update to Unity v2.3

### v2.1.1

-   Update to Sounds 2.0

### v2.1.0

-   Flip to Shhh now gets disables when module is uninstalled

### v2.0.9

-   Downgrade to Sounds 1.0 (4795461) for support for Oreo

### v2.0.8

-   Update to Unity v2.2

### v2.0.7

-   Update Google Sound Picker

### v2.0.6

-   Enables `AutoDndGesturesSettingsActivity` on boot

### v2.0.5

-   Enables `AutoDndGesturesSettingsActivity` for Flip to Shhh

### v2.0.4

-   Enable Flip to Shhh via new method

### v2.0.3

-   Revert Flip to Shhh changes until a proper enabler is found

### v2.0.2

-   Enable Flip to Shhh

### v2.0.1

-   Update Pixel Stand
-   Update Google Sound Picker
-   Update Google Markup

### v2

-   Remove doze bools from overlay
-   Include Google Markup
-   Include Google Sound Picker
-   Update Digital Wellbeing

### v1.9.2

-   Update overlay

### v1.9.1

-   Removed vibration mods for the SPECIAL SNOWFLAKES

### v1.9

-   Enable Google Dialer's Call Screening
-   Disable AOD (again)

### v1.8.1

-   Return to the Magisk Repo
-   Return of Launcher choices (Rootless Launcher, Lawnchair, Ruthless Launcher, Customized Pixel Launcher, stock Pixel Launcher)
-   Return of Launcher homescreen backup/restore
-   Return of Digital Wellbeing to Settings app
-   Return of Pixel Stand
-   Add translations to Gestures app

### v1.7.3

-   Remove AOD (again)

### v1.7.2

-   Quick fix to Device Gestures

### v1.7.1

-   Fix vibration pattern (again)
-   Add config_ringtoneEffectUris from Pixel 3 XL
-   Enable AOD but have it disabled by default

### v1.7

-   Add vibration feedback from Pixel 2 XL instead of Pixel 3 XL

### v1.6

-   Fix Pixel 3 XL values

### v1.4.2

-   Re-add Device Gestures

### v1.4.1

-   Enable swipe up gestures
-   Enable rounded corners
-   Enable Pixel 3 haptic feedback

### v1.4

-   Add Pixel 3 XL values to bools

### v1.3

-   Fix Unity template to avoid bootloops caused by the overlay

### v1.1

-   Remove Google Dialer support to avoid conflicts with Moto Dialer

### v1

-   Re-added to the Repo

## ⭐ Contributors

-   **Pika**, for code reviews and support
-   **JohnFawkes**, for debugging help
-   **thehappydinoa**, for the Google Call Screening and Flip to Shhh
-   **Laster K.**, for Night Light fixes and Daydream VR additions
-   **Skittles9823**, for helping me rename the module

## ⭐ Thanks!

-   Thanks to @Didgeridoohan for his magisk hide props config logging code
-   Thanks to @veez21 for his mod-util terminal script template
-   Thanks to @TadiT7 for xmlpak
-   Thanks to @zackptg5 for Unity and cleaning up our code
-   Thanks to @TopJohnWu for Magisk

## ⭐ Links

-   [![LICENSE](https://img.shields.io/github/license/Magisk-Modules-Repo/Pix3lify.svg)](https://github.com/Magisk-Modules-Repo/Pix3lify/blob/master/LICENSE)
-   [![Pix3lify XDA Portal feature](https://img.shields.io/badge/XDA-Portal-orange.svg)](https://www.xda-developers.com/pixel-2-experience-magisk-module/)
-   [![Source Code](https://img.shields.io/badge/Github-Source-black.svg)](https://github.com/Magisk-Modules-Repo/Pix3lify)
