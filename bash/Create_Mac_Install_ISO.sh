#!/usr/bin/env bash

cd /tmp

bash -c "hdiutil attach /tmp/Catalina.dmg -noverify -nobrowse -mountpoint /Volumes/Catalina"

# does this have a -nobrowse option? This appears on the desktop
bash -c "sudo /Applications/Install\ macOS\ Catalina\ Beta.app/Contents/Resources/createinstallmedia --volume /Volumes/Catalina --nointeraction"

