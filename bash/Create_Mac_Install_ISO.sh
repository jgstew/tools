#!/usr/bin/env bash

# exists files "/Applications/Install macOS Catalina Beta.app/Contents/Resources/createinstallmedia"

cd /tmp

bash -c "hdiutil attach /tmp/Catalina.dmg -noverify -nobrowse -mountpoint /Volumes/Catalina"

# does this have a -nobrowse option? This appears on the desktop
bash -c "sudo /Applications/Install\ macOS\ Catalina\ Beta.app/Contents/Resources/createinstallmedia --volume /Volumes/Catalina --nointeraction"

# get this path dynamically with relevance instead?
bash -c "hdiutil detach /volumes/Install\ macOS\ Catalina\ Beta"

