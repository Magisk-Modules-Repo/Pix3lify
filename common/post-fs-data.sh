# This script will be executed in post-fs-data mode
# More info in the main Magisk thread

[ -f "$MOUNTPATH/Pix3lify/system/bin/xmlstarlet" ] && alias xmlstarlet=$MOUNTPATH/Pix3lify/system/bin/xmlstarlet



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
