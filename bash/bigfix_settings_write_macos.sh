#!/usr/bin/env bash

# use bigfix agent to write client settings

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

"/Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgent" -setSettings "$jsonFile"
