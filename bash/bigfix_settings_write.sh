
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
sudo /usr/libexec/plistbuddy -c "Set :Settings:Client:$1:Value $2" /Library/Preferences/com.bigfix.BESAgent.plist
sudo /usr/libexec/plistbuddy -c "Print :Settings:Client:$1:Value" /Library/Preferences/com.bigfix.BESAgent.plist

# Linux/Unix ? TODO
