#!/usr/bin/env bash

# use bigfix agent to write client settings
# since this method uses the agent itself, stopping cfprefsd is not required!
# this is meant to be used after the agent is already installed.

# Make sure values are provided:
if [ -n "$1" ]; then
  if [ -n "$2" ]; then
    echo Setting $1 to $2
  else
    echo Must Provide Value
    exit 2
  fi
else
  echo Must Provide Setting
  exit 1
fi

jsonFile="bigfix_client_settings_temp.json"
clientSettingsFile="bigfix_client_settings_temp.cfg"
scriptConvert="/Library/BESAgent/BESAgent.app/Contents/MacOS/CfgToJSON.pl"

if [ -f "/Library/BESAgent/BESAgent.app/Contents/MacOS/CfgToPList.pl" ]; then
  scriptConvert="/Library/BESAgent/BESAgent.app/Contents/MacOS/CfgToPList.pl"
fi

echo $1=$2 > "$clientSettingsFile"

"$scriptConvert" "$clientSettingsFile" "$jsonFile"

start_bigfix=false
# if BigFix was running when script started, then start it at the end
if sudo /Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgentControlPanel.sh -status | grep -q 'Running'; then
  start_bigfix=true
  echo stopping the bigfix client so the edit will work:

  sudo /Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgentControlPanel.sh -stop
  sudo /Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgentControlPanel.sh -status
fi

# set setting:
sudo "/Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgent" -setSettings "$jsonFile"

# start bigfix client again if it was running at the start
if [ "$start_bigfix" = true ] ; then
  echo ""
  echo starting bigfix:
  sudo /Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgentControlPanel.sh -start
  sudo /Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgentControlPanel.sh -status
  echo ""
fi

# cleanup temp files:
rm "$clientSettingsFile"
rm "$jsonFile"
