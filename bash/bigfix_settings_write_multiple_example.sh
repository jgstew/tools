
# TODO: come up with a solution in python or similar
#    - https://gist.github.com/gregneagle/01c99322cf985e771827
# PlistBuddy does not work correctly on MacOS due to CFPrefs caching without stopping the agent first

start_bigfix=false
# if BigFix was running when script started, then start it at the end
if sudo /Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgentControlPanel.sh -status | grep -q 'Running'; then
  start_bigfix=true
  echo stopping the bigfix client so the edit will work:

  sudo /Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgentControlPanel.sh -stop
  sudo /Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgentControlPanel.sh -status
  echo ""
fi

bash bigfix_settings_write.sh _BESClient_Download_UtilitiesCacheLimitMB 500
bash bigfix_settings_write.sh _BESClient_Log_Days 35
bash bigfix_settings_write.sh _BESClient_Log_MaxSize 1536000
bash bigfix_settings_write.sh _BESClient_ActionManager_HistoryKeepDays 1825

# start bigfix client again if it was running at the start
if [ "$start_bigfix" = true ] ; then
  echo starting bigfix:
  sudo /Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgentControlPanel.sh -start
  sudo /Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgentControlPanel.sh -status
  echo ""
fi
