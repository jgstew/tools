#!/usr/bin/env swift

import Swift
// test running swift on any platform


// TODO: get x64 native tools command prompt location:
// https://stackoverflow.com/questions/63319478/how-do-i-setup-msvc-native-tools-command-prompt-from-bat-file
// Example: C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build

// Powershell get build tools dir:
// Get-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select DisplayName,InstallLocation | Where-Object { $_.DisplayName -match "Visual Studio Build Tools" } | Select InstallLocation | Select-Object -first 1 | Select -ExpandProperty "InstallLocation"

// Example: call "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

print("Working!")
