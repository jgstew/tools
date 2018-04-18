
echo PlistBuddy does not work correctly on MacOS due to CFPrefs caching.
exit 999

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
sudo /usr/libexec/plistbuddy -c "Set :Settings:Client:$1:Value $2" /Library/Preferences/com.bigfix.BESAgent.plist
sudo /usr/libexec/plistbuddy -c "Print :Settings:Client:$1:Value" /Library/Preferences/com.bigfix.BESAgent.plist

# Linux/Unix ? TODO
