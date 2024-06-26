#!/usr/bin/env bash

echo "See this method instead: https://github.com/jgstew/tools/blob/master/bash/bigfix_settings_write_macos.sh"
exit 9

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
  # must stop cfprefsd to allow plistbuddy's changes to take effect.
  sudo launchctl stop com.apple.cfprefsd.xpc.daemon
fi

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

# OS X
# NOTE: the following is only valid if working with plain files not in use by BigFix/CFPrefs
#        see here: https://macmule.com/2014/02/07/mavericks-preference-caching/
sudo /usr/libexec/plistbuddy -c "Add :Settings:Client:$1:Value string $2" /Library/Preferences/com.bigfix.BESAgent.plist
sudo /usr/libexec/plistbuddy -c "Set :Settings:Client:$1:Value $2" /Library/Preferences/com.bigfix.BESAgent.plist
# Related: https://github.com/jgstew/tools/blob/master/bash/date_plistbuddy.sh
sudo /usr/libexec/plistbuddy -c "Add :Settings:Client:$1:Date date `date +"%a %b %d %T %Z %Y"`" /Library/Preferences/com.bigfix.BESAgent.plist
sudo /usr/libexec/plistbuddy -c "Set :Settings:Client:$1:Date `date +"%a %b %d %T %Z %Y"`" /Library/Preferences/com.bigfix.BESAgent.plist

echo Settings is now:
sudo /usr/libexec/plistbuddy -c "Print :Settings:Client:$1:Value" /Library/Preferences/com.bigfix.BESAgent.plist

# start bigfix client again if it was running at the start
if [ "$start_bigfix" = true ] ; then
  # restart cfprefsd
  sudo launchctl start com.apple.cfprefsd.xpc.daemon
  echo starting bigfix:
  sudo /Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgentControlPanel.sh -start
  sudo /Library/BESAgent/BESAgent.app/Contents/MacOS/BESAgentControlPanel.sh -status
  echo ""
fi
