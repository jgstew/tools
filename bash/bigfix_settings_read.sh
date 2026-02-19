
# OS X
# https://macmule.com/2014/02/07/mavericks-preference-caching/
# https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Tivoli+Endpoint+Manager/page/Common+File+Locations

# defaults read /Library/Preferences/com.bigfix.BESAgent Settings

# https://www.marcosantadev.com/manage-plist-files-plistbuddy/
# only if PlistBuddy binary is found:
if [ -x "/usr/libexec/PlistBuddy" ]; then
  /usr/libexec/PlistBuddy -c "print Settings:Client" /Library/Preferences/com.bigfix.BESAgent.plist
else

# Linux/Unix
awk -F'[\\\[]=]' '/^\[/ {
    # Extract the string between the last backslash and the closing bracket
    n = split($0, a, "\\");
    id = a[n];
    sub(/].*/, "", id);
}
/^[Vv]alue/ {
    # Extract the value after the equals sign and strip whitespace
    split($0, v, "=");
    val = v[2];
    gsub(/[[:space:]]/, "", val);
    if (id != "") print id "=" val;
}' besclient.config

fi
