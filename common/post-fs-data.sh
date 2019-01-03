# This script will be executed in post-fs-data mode
# More info in the main Magisk thread

if [ $API -ge 28 ]; then
  DIALER_PREF_FILE=/data/data/com.google.android.dialer/shared_prefs/dialer_phenotype_flags.xml
  if [ -f $DIALER_PREF_FILE ]; then
    # Enabling Google's Call Screening
    sed -i 's/name="G__speak_easy_bypass_locale_check" value="false"/name="G__speak_easy_bypass_locale_check" value="true"/g' $DIALER_PREF_FILE
    sed -i 's/name="G__speak_easy_enable_listen_in_button" value="false"/name="G__speak_easy_enable_listen_in_button" value="true"/g' $DIALER_PREF_FILE
    sed -i 's/name="__data_rollout__SpeakEasy.OverrideUSLocaleCheckRollout__launched__" value="false"/name="__data_rollout__SpeakEasy.OverrideUSLocaleCheckRollout__launched__" value="true"/g' $DIALER_PREF_FILE
    sed -i 's/name="G__enable_speakeasy_details" value="false"/name="G__enable_speakeasy_details" value="true"/g' $DIALER_PREF_FILE
    sed -i 's/name="G__speak_easy_enabled" value="false"/name="G__speak_easy_enabled" value="true"/g' $DIALER_PREF_FILE
    sed -i 's/name="G__speakeasy_show_privacy_tour" value="false"/name="G__speakeasy_show_privacy_tour" value="true"/g' $DIALER_PREF_FILE
    sed -i 's/name="__data_rollout__SpeakEasy.SpeakEasyDetailsRollout__launched__" value="false"/name="__data_rollout__SpeakEasy.SpeakEasyDetailsRollout__launched__" value="true"/g' $DIALER_PREF_FILE
    sed -i 's/name="__data_rollout__SpeakEasy.CallScreenOnPixelTwoRollout__launched__" value="false"/name="__data_rollout__SpeakEasy.CallScreenOnPixelTwoRollout__launched__" value="true"/g' $DIALER_PREF_FILE
    sed -i 's/name="G__speakeasy_postcall_survey_enabled" value="false"/name="G__speakeasy_postcall_survey_enabled" value="true"/g' $DIALER_PREF_FILE
  fi
fi
