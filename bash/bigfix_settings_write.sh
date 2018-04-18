
# OS X
# TODO: make sure values are given
sudo /usr/libexec/plistbuddy -c "Set :Settings:Client:$1:Value $2" /Library/Preferences/com.bigfix.BESAgent.plist
sudo /usr/libexec/plistbuddy -c "Print :Settings:Client:$1:Value" /Library/Preferences/com.bigfix.BESAgent.plist

# Linux/Unix ? TODO
