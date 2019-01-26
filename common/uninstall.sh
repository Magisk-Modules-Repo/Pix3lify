if $MAGISK; then
  magiskpolicy --live "create system_server sdcardfs file" "allow system_server sdcardfs file { write }"
fi

if [ $API -ge 28 ]; then
  ui_print " "
  ui_print "   Disabling Google's Call Screening..."
  DPF=$(find /data/data/com.google.android.dialer*/shared_prefs/ -name "dialer_phenotype_flags.xml")
  if [ -f $DPF ]; then
    sed -i "/<!--$MODID-->/d" $DPF
    sed -i -e "s|<!--$MODID\(.*\)|\1|g" -e "s|\(.*\)$MODID-->|\1|g" $DPF
    if $BOOTMODE; then
      am force-stop "com.google.android.dialer"
    fi
  fi
fi

ui_print " "
ui_print "   Disabling Google's Flip to Shhh..."
# Disabling Google's Flip to Shhh
WELLBEING_PREF_FILE=$(find /data/data/com.google.android.apps.wellbeing*/shared_prefs -name "PhenotypePrefs.xml")
if [ -f $WELLBEING_PREF_FILE ]; then
  rm -f $WELLBEING_PREF_FILE
  if $BOOTMODE; then
    am force-stop "com.google.android.apps.wellbeing"
  fi
fi

OVERLAY='/data/resource-cache/overlays.list'
if [ -f "$OVERLAY" ]; then
  ui_print " "
  ui_print "   Removing $OVERLAY"
  rm -f "$OVERLAY"
fi
