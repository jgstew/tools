
' From: https://www.bigfix.me/fixlet/details/741

Set oWS = WScript.CreateObject("WScript.Shell")
sLinkFile = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Skype.lnk"

Set oLink = oWS.CreateShortcut(sLinkFile)
    oLink.TargetPath = "C:\Program Files\Skype\Phone\Skype.exe"
    oLink.Save
