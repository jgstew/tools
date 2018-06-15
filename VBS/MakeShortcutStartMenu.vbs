
' From: https://www.bigfix.me/fixlet/details/741
' NOTE: this won't work as is due to relevance substitution being required in it's current form.

Set oWS = WScript.CreateObject("WScript.Shell")
sLinkFile = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Skype.lnk"

Set oLink = oWS.CreateShortcut(sLinkFile)
    oLink.TargetPath = "C:\Program Files\Skype\Phone\Skype.exe"
    oLink.Save
