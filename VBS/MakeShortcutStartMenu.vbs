
' From: https://www.bigfix.me/fixlet/details/741
' NOTE: this won't work as is due to relevance substitution being required in it's current form.

Set oWS = WScript.CreateObject("WScript.Shell")
sLinkFile = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Skype.lnk"
Set oLink = oWS.CreateShortcut(sLinkFile)
oLink.TargetPath = "{(value "DisplayIcon" of key whose (value "displayname" of it as string contains "Skype" of it AND value "displayname" of it as string as lowercase does not contain "Click to Call" as lowercase) of key "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" of registry as string)}"
oLink.Save
