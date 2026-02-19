#!/bin/bash

# OS X
# https://macmule.com/2014/02/07/mavericks-preference-caching/
# https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Tivoli+Endpoint+Manager/page/Common+File+Locations

# defaults read /Library/Preferences/com.bigfix.BESAgent Settings

# https://www.marcosantadev.com/manage-plist-files-plistbuddy/
# only if PlistBuddy binary is found:
if [ -x "/usr/libexec/PlistBuddy" ]; then

echo "BigFix Client Settings (using PlistBuddy):"
echo ""
/usr/libexec/PlistBuddy -c "print Settings:Client" /Library/Preferences/com.bigfix.BESAgent.plist | awk '
/ = Dict {/ {
    # The key is everything before " = Dict {"
    key = $0
    sub(/ = Dict {/, "", key)
    # Strip leading whitespace
    sub(/^[[:space:]]+/, "", key)
}
/^[[:space:]]*Value = / {
    # The value is everything after "Value = "
    val = $0
    sub(/^[[:space:]]*Value = /, "", val)

    # Print them together
    # Print ONLY if the key is not empty AND does not start with __Group___AdminBy___
    if (key != "" && key !~ /^__Group___AdminBy___/) {
        print key "=" val
    }
}'

else

# 1. Define the possible file paths in an array (order matters!)
paths=(
    "/var/opt/BESClient/besclient.config"
    "./persistent/var/opt/BESClient/besclient.config"
    "./var/opt/BESClient/besclient.config"
    "./besclient.config"
)

target_file=""

# 2. Loop through the array to find the first readable file
for file in "${paths[@]}"; do
    if [[ -r "$file" ]]; then
        target_file="$file"
        echo "Found config at: $target_file" >&2  # Optional: Prints to stderr so it doesn't mess up your output
        break # Stop looking once we find one!
    fi
done

# 3. If no file was found, throw an error and exit
if [[ -z "$target_file" ]]; then
    echo "Error: besclient.config not found or not readable in any of the expected locations." >&2
    exit 1
fi

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
}' "$target_file"

fi
