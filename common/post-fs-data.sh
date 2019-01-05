# This script will be executed in post-fs-data mode
# More info in the main Magisk thread

[ -f "$MOUNTPATH/Pix3lify/system/bin/xmlstarlet" ] && alias xmlstarlet=$MOUNTPATH/Pix3lify/system/bin/xmlstarlet

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
    *dialer_phenotype_flags*.xml) VAR1=boolean; VAR2=string; VAR3=long;;
    *mixer_paths*.xml) VAR1=ctl; VAR2=mixer;;
    *sapa_feature*.xml) VAR1=feature; VAR2=model;;
    *mixer_gains*.xml) VAR1=ctl; VAR2=mixer;;
    *audio_device*.xml) VAR1=kctl; VAR2=mixercontrol;;
    *audio_platform_info*.xml) VAR1=param; VAR2=config_params;;
  esac
  if [ "$1" == "-t" -o "$1" == "-ut" -o "$1" == "-tu" ] && [ "$VAR1" ]; then
    if [ "$(grep "<$VAR1 $NAMEC=\"$NAME\" $VALC=\".*\" />" $2)" ]; then
      sed -i "0,/<$VAR1 $NAMEC=\"$NAME\" $VALC=\".*\" \/>/ s/\(<$VAR1 $NAMEC=\"$NAME\" $VALC=\"\).*\(\" \/>\)/\1$VAL\2/" $2
    elif [ "$1" == "-t" ]; then
      sed -i "/<$VAR2>/ a\    <$VAR1 $NAMEC=\"$NAME\" $VALC=\"$VAL\" \/>" $2
    fi
  elif [ "$(xmlstarlet sel -t -m "$3" -c . $2)" ]; then
    [ "$(xmlstarlet sel -t -m "$3" -c . $2 | sed -r "s/.*$VALC=\"(.*)\".*/\1/")" == "$VAL" ] && return
    case "$1" in
      "-u"|"-s") xmlstarlet ed -L -u "$3/@$VALC" -v "$VAL" $2;;
      "-d") xmlstarlet ed -L -d "$3" $2;;
    esac
  elif [ "$1" == "-s" ]; then
    local NP=$(echo "$3" | sed -r "s|(^.*)/.*$|\1|")
    local SNP=$(echo "$3" | sed -r "s|(^.*)\[.*$|\1|")
    local SN=$(echo "$3" | sed -r "s|^.*/.*/(.*)\[.*$|\1|")
    xmlstarlet ed -L -s "$NP" -t elem -n "$SN-Pix3lify" -i "$SNP-Pix3lify" -t attr -n "$NAMEC" -v "$NAME" -i "$SNP-Pix3lify" -t attr -n "$VALC" -v "$VAL" $2
    xmlstarlet ed -L -r "$SNP-Pix3lify" -v "$SN" $2
  fi
}

if [ $API -ge 28 ]; then
  DPF=/data/data/com.google.android.dialer/shared_prefs/dialer_phenotype_flags.xml
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
    