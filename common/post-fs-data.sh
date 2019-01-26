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
    *dialer_phenotype_flags*.xml)  VAR1=boolean; VAR2=string; VAR3=long;;
    *mixer_paths*.xml) VAR1=ctl; VAR2=mixer;;
    *sapa_feature*.xml) VAR1=feature; VAR2=model;;
    *mixer_gains*.xml) VAR1=ctl; VAR2=mixer;;
    *audio_device*.xml) VAR1=kctl; VAR2=mixercontrol;;
    *audio_platform_info*.xml) VAR1=param; VAR2=config_params;;
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

(
if [ $API -ge "28" ]; then
  DPF=$(find /data/data/com.google.android.dialer*/shared_prefs/ -name "dialer_phenotype_flags.xml")
  if [ -f $DPF ]; then
    # Enabling Google's Call Screening
    #DIALERPATCHES
  fi
fi
)&