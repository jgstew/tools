#!/usr/bin/env bash

cd /tmp

bash -c "hdiutil attach /tmp/Catalina.dmg -noverify -nobrowse -mountpoint /Volumes/Catalina"

bash -c "sudo /Applications/Install\ macOS\ Catalina\ Beta.app/Contents/Resources/createinstallmedia --volume /Volumes/Catalina --nointeraction"

