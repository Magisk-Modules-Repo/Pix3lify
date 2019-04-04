patch_xml() {
  local VAR1 VAR2 NAME NAMEC VALC VAL
  NAME=$(echo "$3" | sed -r "s|^.*/.*\[@.*=\"(.*)\".*$|\1|")
  NAMEC=$(echo "$3" | sed -r "s|^.*/.*\[@(.*)=\".*\".*$|\1|")
  if [ "$(echo $4 | grep '=')" ]; then
    VALC=$(echo "$4" | sed -r "s|(.*)=.*|\1|"); VAL=$(echo "$4" | sed -r "s|.*=(.*)|\1|")
  else
    VALC="value"; VAL="$4"
  fi
  case $2 in
    *dialer_phenotype_flags*.xml)  sed -i "/#DIALERPATCHES/a\          patch_xml $1 \$MODPATH/\ '$3' \"$4\"" $TMPDIR/common/post-fs-data.sh; VAR1=boolean; VAR2=string;;
  esac
  if [ "$1" == "-t" -o "$1" == "-ut" -o "$1" == "-tu" ] && [ "$VAR1" ]; then
    if [ "$(grep "<$VAR1 $NAMEC=\"$NAME\" $VALC=\".*\" />" $2)" ]; then
      sed -i "0,/<$VAR1 $NAMEC=\"$NAME\" $VALC=\".*\" \/>/ {/<$VAR1 $NAMEC=\"$NAME\" $VALC=\".*\" \/>/p; s/\(<$VAR1 $NAMEC=\"$NAME\" $VALC=\".*\" \/>\)/<!--$MODID\1$MODID-->/}" $2
      sed -i "0,/<$VAR1 $NAMEC=\"$NAME\" $VALC=\".*\" \/>/ s/\(<$VAR1 $NAMEC=\"$NAME\" $VALC=\"\).*\(\" \/>\)/\1$VAL\2<!--$MODID-->/" $2
    elif [ "$1" == "-t" ]; then
      sed -i "/<$VAR2>/ a\    <$VAR1 $NAMEC=\"$NAME\" $VALC=\"$VAL\" \/><!--$MODID-->" $2
    fi
  elif [ "$(xmlstarlet sel -t -m "$3" -c . $2)" ]; then
    [ "$(xmlstarlet sel -t -m "$3" -c . $2 | sed -r "s/.*$VALC=(\".*\").*/\1/")" == "$VAL" ] && return
    xmlstarlet ed -P -L -i "$3" -t elem -n "$MODID" $2
    sed -ri "s/(^ *)(<$MODID\/>)/\1\2\n\1/g" $2
    local LN=$(sed -n "/<$MODID\/>/=" $2)
    for i in ${LN}; do
      sed -i "$i d" $2
      case $(sed -n "$((i-1)) p" $2) in
        *">$MODID-->") sed -i -e "${i-1}s/<!--$MODID-->//" -e "${i-1}s/$/<!--$MODID-->/" $2;;
        *) sed -i "$i p" $2
           sed -ri "${i}s/(^ *)(.*)/\1<!--$MODID\2$MODID-->/" $2
           sed -i "$((i+1))s/$/<!--$MODID-->/" $2;;
      esac
    done
    case "$1" in
      "-u"|"-s") xmlstarlet ed -L -u "$3/@$VALC" -v "$VAL" $2;;
      "-d") xmlstarlet ed -L -d "$3" $2;;
    esac
  elif [ "$1" == "-s" ]; then
    local NP=$(echo "$3" | sed -r "s|(^.*)/.*$|\1|")
    local SNP=$(echo "$3" | sed -r "s|(^.*)\[.*$|\1|")
    local SN=$(echo "$3" | sed -r "s|^.*/.*/(.*)\[.*$|\1|")
    xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" -i "$SNP-$MODID" -t attr -n "$NAMEC" -v "$NAME" -i "$SNP-$MODID" -t attr -n "$VALC" -v "$VAL" $2
    xmlstarlet ed -L -r "$SNP-$MODID" -v "$SN" $2
    xmlstarlet ed -L -i "$3" -t elem -n "$MODID" $2
    local LN=$(sed -n "/<$MODID\/>/=" $2)
    for i in ${LN}; do
      sed -i "$i d" $2
      sed -ri "${i}s/$/<!--$MODID-->/" $2
    done
  fi
  local LN=$(sed -n "/^ *<!--$MODID-->$/=" $2 | tac)
  for i in ${LN}; do
    sed -i "$i d" $2
    sed -ri "$((i-1))s/$/<!--$MODID-->/" $2
  done
}

OIFS=$IFS; IFS=\|
case $(echo $(basename $ZIPFILE) | tr '[:upper:]' '[:lower:]') in
  *full*) FULL=true;;
  *slim*) FULL=false;;
esac
case $(echo $(basename $ZIPFILE) | tr '[:upper:]' '[:lower:]') in
  *over*) OVER=true;;
  *nover*) OVER=false;;
esac
case $(echo $(basename $ZIPFILE) | tr '[:upper:]' '[:lower:]') in
  *font*) FONT=true;;
  *nfont*) FONT=false;;
esac
case $(echo $(basename $ZIPFILE) | tr '[:upper:]' '[:lower:]') in
  *acc*) ACC=true;;
  *nacc*) ACC=false;;
esac
IFS=$OIFS

## Debug Stuff
log_start
log_print "- Installing Logging Scripts/Prepping Terminal Script "
cp_ch -n $TMPDIR/pix3lify.sh $UNITY/system/bin/pix3lify

sed -i "s|<CACHELOC>|$CACHELOC|" $UNITY/system/bin/pix3lify
if $MAGISK; then
  sed -i "s|<MODPROP>|$(echo $MOD_VER)|" $UNITY/system/bin/pix3lify
else
  sed -i "s|<MODPROP>|$MOD_VER|" $UNITY/system/bin/pix3lify
fi
patch_script $UNITY/system/bin/pix3lify

if [ "$PX1" ] || [ "$PX1XL" ] || [ "$PX2" ] || [ "$PX2XL" ] || [ "$PX3" ] || [ "$PX3XL" ] || [ "$N5X" ] || [ "$N6P" ] || [ "$OOS" ]; then
  ui_print " "
  log_print "   Pix3lify is only for non-Google devices!"
  log_print "   DO YOU WANT TO IGNORE OUR WARNINGS AND RISK A BOOTLOOP?"
  log_print "   Vol Up = Yes, Vol Down = No"
  if $VKSEL; then
    ui_print " "
    log_print "   Ignoring warnings..."
  else
    ui_print " "
    log_print "   Exiting..."
    abort >> $INSTLOG 2>&1
  fi
fi

ui_print " "
log_print "   Removing remnants from past Pix3lify installs..."
# Removes /data/resource-cache/overlays.list
OVERLAY='/data/resource-cache/overlays.list'
if [ -f "$OVERLAY" ]; then
  log_print "   Removing $OVERLAY"
  rm -f "$OVERLAY"
fi

if [ -z $FULL ] || [ -z $OVER ] || [ -z $FONT ] || [ -z $ACC ]; then
  if [ -z $FULL ]; then
    ui_print " "
    log_print " - Slim Options -"
    log_print "   Do you want to enable slim mode (heavily reduced featureset, see README)?"
    log_print "   Vol Up = Yes, Vol Down = No"
    if $VKSEL; then
      FULL=false >> $INSTLOG 2>&1
    else
      FULL=true >> $INSTLOG 2>&1
    fi
  fi
  if $FULL && ([ -z $OVER ] || [ -z $FONT ] || [ -z $ACC ]); then
    ui_print " "
    log_print " - Font Options -"
    log_print "   Do you want to replace fonts with Product Sans?"
    log_print "   Vol Up = Yes, Vol Down = No"
    if $VKSEL; then
      FONT=true >> $INSTLOG 2>&1
    else 
      FONT=false >> $INSTLOG 2>&1
    fi
    if [ -z $OVER ]; then
      if [ "$OOS" ]; then
        log_print "   Pix3lify overlay has been known to not work and cause issues on devices running OxygenOS!"
        log_print "   DO YOU WANT TO IGNORE OUR WARNINGS AND RISK A BOOTLOOP?"
        log_print "   Vol Up = Yes, Vol Down = No"
        if $VKSEL; then
          ui_print " "
          log_print "   Ignoring warnings..."
          ui_print " "
          log_print " - Framework Options -"
          log_print "   Do you want the Pixel framework enabled?"
          log_print "   Vol Up = Yes, Vol Down = No"
          if $VKSEL; then
            OVER=true >> $INSTLOG 2>&1
          else
            OVER=false >> $INSTLOG 2>&1
          fi
        else
          ui_print " "
          log_print "  Disabling Overlay to prevent bootloop"
          OVER=false
        fi
      else
        ui_print " "
        log_print " - Framework Options -"
        log_print "   Do you want the Pixel framework enabled?"
        log_print "   Vol Up = Yes, Vol Down = No"
        if $VKSEL; then
          OVER=true >> $INSTLOG 2>&1
        else
          OVER=false >> $INSTLOG 2>&1
        fi
      fi
    fi
    if [ -z $ACC ]; then
      log_print " - Accent Options -"
      log_print "   Do you want the Pixel accent enabled?"
      log_print "   Vol Up = Yes, Vol Down = No"
      if $VKSEL; then
        ACC=true >> $INSTLOG 2>&1
      else
        ACC=false >> $INSTLOG 2>&1
      fi
    fi
  fi
else
  ui_print " Options specified in zip name!"
fi

if [ ! -f "/system/bin/curl" ]; then
  cp_ch $TMPDIR/curl $UNITY/system/bin/curl
fi

if $FULL; then
  ui_print " "
  log_print " Full mode selected..."
  sed -ri "s/name=(.*)/name=\1 (FULL)/" $TMPDIR/module.prop
  prop_process $TMPDIR/common/full.prop
  if $OVER; then
    ui_print " "
    log_print "   Enabling Pixel framework..."
  else
    ui_print " "
    log_print "   Disabling Pixel framework..."
    rm -f $TMPDIR/system/vendor/overlay/Pix3lify.apk >> $INSTLOG 2>&1
    rm -rf /data/resource-cache >> $INSTLOG 2>&1
    rm -rf /data/dalvik-cache >> $INSTLOG 2>&1
    log_print "   Dalvik-Cache has been cleared!"
    log_print "   Next boot may take a little longer to boot!"
  fi
  if $ACC; then
    ui_print " "
    log_print "   Enabling Pixel accent..."
  else
    ui_print " "
    log_print "   Disabling Pixel accent..."
    sed -i 's/ro.boot.vendor.overlay.theme/# ro.boot.vendor.overlay.theme/g' $TMPDIR/common/system.prop
    rm -rf $TMPDIR/system/vendor/overlay/Pixel >> $INSTLOG 2>&1
    rm -rf /data/resource-cache >> $INSTLOG 2>&1
  fi
else
  ui_print " "
  log_print "   Enabling slim mode..."
  sed -ri "s/name=(.*)/name=\1 (SLIM)/" $TMPDIR/module.prop
  rm -rf $TMPDIR/system/app >> $INSTLOG 2>&1
  rm -rf $TMPDIR/system/fonts >> $INSTLOG 2>&1
  rm -rf $TMPDIR/system/lib >> $INSTLOG 2>&1
  rm -rf $TMPDIR/system/lib64 >> $INSTLOG 2>&1
  rm -rf $TMPDIR/system/media >> $INSTLOG 2>&1
  rm -rf $TMPDIR/system/priv-app >> $INSTLOG 2>&1
  rm -rf $TMPDIR/system/vendor/overlay/DisplayCutoutEmulationCorner >> $INSTLOG 2>&1
  rm -rf $TMPDIR/system/vendor/overlay/DisplayCutoutEmulationDouble >> $INSTLOG 2>&1
  rm -rf $TMPDIR/system/vendor/overlay/DisplayCutoutEmulationTall >> $INSTLOG 2>&1
  rm -rf $TMPDIR/system/vendor/overlay/DisplayCutoutNoCutout >> $INSTLOG 2>&1
  rm -rf $TMPDIR/system/vendor/overlay/Pixel >> $INSTLOG 2>&1
  rm -rf /data/resource-cache >> $INSTLOG 2>&1
fi

#if $BOOT; then
#  ui_print " "
#  log_print "   Enabling boot animation..."
#  cp_ch -i $TMPDIR/common/bootanimation.zip $UNITY$BFOLDER$BZIP
#else
#  ui_print " "
#  log_print "   Disabling boot animation..."
#fi

if $FONT; then
  ui_print " "
  log_print "   Enabling fonts replacement..."
  cp -rf /system/etc/fonts.xml $TMPDIR/system/etc/fonts.xml
  for i in $(find $TMPDIR/system/fonts/GoogleSans-* | sed 's|.*-||'); do
    sed -i "s|Roboto-$i|GoogleSans-$i|" $TMPDIR/system/etc/fonts.xml
  done
  for i in $(find /system/fonts/Clock* | sed 's|.*-||'); do
    sed -i "s|Clock$i|AndroidClock|" $TMPDIR/system/etc/fonts.xml
  done
  fontls() {
    ui_print " "
    log_print "   Replacing LockScreen Font.."
  }
  if [[ ! -e /system/fonts/AndroidClock.ttf ]]; then
    for j in /system/fonts/Clock*; do
      [ -e "$j" ] && fontls || rm -rf $TMPDIR/system/etc/fonts.xml
      break
    done
  fi
else
  ui_print " "
  log_print "   Disabling fonts replacement..."
  rm -rf $TMPDIR/system/etc/fonts.xml >> $INSTLOG 2>&1
fi

if [ $API -ge 27 ]; then
  rm -rf $TMPDIR/system/framework  >> $INSTLOG 2>&1
fi

if [ $API -ge 28 ]; then
  ui_print " "
  log_print "   Enabling Google's Call Screening..."
  DPF=$(find /data/data/com.google.android.dialer* -name "dialer_phenotype_flags.xml")
  if [ -f $DPF ]; then
    # Enabling Google's Call Screening
    patch_xml -s $DPF '/map/boolean[@name="G__speak_easy_bypass_locale_check"]' "true"
    patch_xml -s $DPF '/map/boolean[@name="G__speak_easy_enable_listen_in_button"]' "true"
    patch_xml -s $DPF '/map/boolean[@name="__data_rollout__SpeakEasy.OverrideUSLocaleCheckRollout__launched__"]' "true"
    patch_xml -s $DPF '/map/boolean[@name="G__enable_speakeasy_details"]' "true"
    patch_xml -s $DPF '/map/boolean[@name="G__speak_easy_enabled"]' "true"
    patch_xml -s $DPF '/map/boolean[@name="G__speakeasy_show_privacy_tour"]' "true"
    patch_xml -s $DPF '/map/boolean[@name="__data_rollout__SpeakEasy.SpeakEasyDetailsRollout__launched__"]' "true"
    patch_xml -s $DPF '/map/boolean[@name="__data_rollout__SpeakEasy.CallScreenOnPixelTwoRollout__launched__"]' "true"
    patch_xml -s $DPF '/map/boolean[@name="G__speakeasy_postcall_survey_enabled"]' "true"
  fi
fi

if [ $API -ge 28 ]; then
  rm -rf $TMPDIR/system/app/MarkupGoogle/MarkupGoogle2.apk >> $INSTLOG 2>&1
  mv $TMPDIR/system/app/MarkupGoogle/MarkupGoogle1.apk $TMPDIR/system/app/MarkupGoogle/MarkupGoogle.apk
elif [ $API -lt 28 ] && [ $API -ge 22 ]; then
  rm -rf $TMPDIR/system/app/MarkupGoogle/MarkupGoogle1.apk >> $INSTLOG 2>&1
  mv $TMPDIR/system/app/MarkupGoogle/MarkupGoogle2.apk $TMPDIR/system/app/MarkupGoogle/MarkupGoogle.apk
else
   rm -rf $TMPDIR/system/app/MarkupGoogle >> $INSTLOG 2>&1    
fi

# Adds full variables to service.sh
for i in "FULL"; do
  sed -i "2i $i=$(eval echo \$$i)" $TMPDIR/common/service.sh
done

cp_ch -i $UF/tools/$ARCH32/xmlstarlet $TMPDIR/system/bin/xmlstarlet

cp_ch -i $UNITY/system/bin/pix3lify $UNITY/pix3lify

ui_print " If you encounter any bugs or issues, please type pix3lify"
ui_print " in a terminal emulator and choose yes to send logs to our server"
ui_print " WE DO NOT COLLECT ANY PERSONAL INFORMATION"
