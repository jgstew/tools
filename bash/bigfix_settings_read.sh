
# OS X
# https://macmule.com/2014/02/07/mavericks-preference-caching/
# https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Tivoli+Endpoint+Manager/page/Common+File+Locations

# defaults read /Library/Preferences/com.bigfix.BESAgent Settings

# https://www.marcosantadev.com/manage-plist-files-plistbuddy/
/usr/libexec/PlistBuddy -c "print Settings:Client" /Library/Preferences/com.bigfix.BESAgent.plist

# Linux/Unix ? TODO
