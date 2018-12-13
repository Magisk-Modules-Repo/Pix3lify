<p align="center">
<b> Pix3lify</b><br>
  <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/5/50/Google_Pixel_%28smartphone%29_logo.svg/800px-Google_Pixel_%28smartphone%29_logo.svg.png">
</p>

<p align="center">
 <a href="https://forum.xda-developers.com/apps/magisk/module-pixel-2-experience-t3757137"><img src="https://img.shields.io/badge/XDA-Thread-orange.svg"></a><br /><a href="https://t.me/PIX3LIFY"><img src="https://img.shields.io/badge/Telegram-Channel-blue.svg"></a>
</p>

## ⭐ Module description
As a Mi A1 user, I was stuck with Stock Oreo 8.0.0 without Oreo custom ROMs when I first bought my device. Kernel sources weren't released at the time so I decided if I can cook up a Magisk module that can bring me the Pixel UI without the need to install that ROM. What I did is to search around the internet which lead me to downloading the Pixel 3 XL factory images and I have extracted the files mostly needed in the new Pixel 3 devices. I've decided to gather these files and compiled them all into a single Magisk Module. This module can be flashed with other devices on Nougat and above as well.

## ⭐ Compatibility
* [![Magisk](https://img.shields.io/badge/Magisk-17%2B-00B39B.svg)](https://forum.xda-developers.com/apps/magisk/official-magisk-v7-universal-systemless-t3473445)
* [![Android Oreo+](https://img.shields.io/badge/Oreo-8.0+-blue.svg)](https://www.android.com/versions/oreo-8-0/)
* Close to Stock/AOSP ROMs (not for MIUI, TouchWiz, EMUI, etc.)
* All root solutions (requires init.d support if not using magisk or supersu. Try [Init.d Injector](https://forum.xda-developers.com/android/software-hacking/mod-universal-init-d-injector-wip-t3692105))

## ⭐ Reminders
* TO COMPLETELY UNINSTALL THE MODULE AND AVOID BOOTLOOPS, INSTALL THE ZIP AGAIN IN MAGISK OR TWRP!!
* Take a full backup before installing the module.

## ⭐ Features
* Different Pixel Launcher choices (Rootless Launcher, Lawnchair, Ruthless Launcher, Customized Pixel Launcher, stock Pixel Launcher)
* Pixel Blue theme accent
* Set Gboard theme to White BG with Pixel Blue accent
* Adds Daydream VR support
* Adds Digital Wellbeing in Settings app
* Adds Gestures in Settings app (device dependent)
* Adds Pixel alarms/media/ringtones/UI sounds
* Adds Pixel Stand app
* Enables Google Dialer's Call Screening (mileage may vary)
* Enables Camera2 API support (find a working Modded Google Camera app [here](https://www.celsoazevedo.com/files/android/google*camera/))
* Enables EIS support (device dependent)
* Enables Google Assistant
* Enables Pixel exclusive wallpapers
* Enables Night Light (device dependent)

## ⭐ Changelog
### v2.0.1
* Return of Pixel Stand
* Update Google Sound Picker
* Update Google Markup

### v2
* Remove doze bools from overlay
* Include Google Markup
* Include Google Sound Picker
* Update Digital Wellbeing

### v1.9.2
* Update overlay

### v1.9.1
* Removed vibration mods for the SPECIAL SNOWFLAKES

### v1.9
* Enable Google Dialer's Call Screening
* Disable AOD (again)

### v1.8.1
* Return to the Magisk Repo
* Return of Launcher choices (Rootless Launcher, Lawnchair, Ruthless Launcher, Customized Pixel Launcher, stock Pixel Launcher)
* Return of Launcher homescreen backup/restore
* Return of Digital Wellbeing to Settings app
* Return of Pixel Stand
* Add translations to Gestures app

### v1.7.3
* Remove AOD (again)

### v1.7.2
* Quick fix to Device Gestures

### v1.7.1
* Fix vibration pattern (again)
* Add config_ringtoneEffectUris from Pixel 3 XL
* Enable AOD but have it disabled by default

### v1.7
* Add vibration feedback from Pixel 2 XL instead of Pixel 3 XL

### v1.6
* Fix Pixel 3 XL values

### v1.4.2
* Re-add Device Gestures

### v1.4.1
* Enable swipe up gestures
* Enable rounded corners
* Enable Pixel 3 haptic feedback

### v1.4
* Add Pixel 3 XL values to bools

### v1.3
* Fix Unity template to avoid bootloops caused by the overlay

### v1.1
* Remove Google Dialer support to avoid conflicts with Moto Dialer

### v1
* Re-added to the Repo

## ⭐ Credits
* @thehappydinoa for the Google Call Screening codes
* @Laster K. for Night Light fixes and Daydream VR additions
* @Skittles9823 for helping me rename the module
* @topjohnwu for Magisk

## ⭐ Links
* [![LICENSE](https://img.shields.io/github/license/Magisk-Modules-Repo/Pix3lify.svg)](https://github.com/Magisk-Modules-Repo/Pix3lify/blob/master/LICENSE)
* [![Pix3lify XDA Portal feature](https://img.shields.io/badge/XDA-Portal-orange.svg)](https://www.xda-developers.com/pixel-2-experience-magisk-module/)
* [![Source Code](https://img.shields.io/badge/Github-Source-black.svg)](https://github.com/Magisk-Modules-Repo/Pix3lify)
