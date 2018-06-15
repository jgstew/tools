
' The microsoft example didn't work on Windows Server 2016 but this did:
'   usage: cscript MakeDesktopShortcutURL.vbs //NoLogo

Set objShell = WScript.CreateObject("WScript.Shell")
strDesktop = objShell.SpecialFolders("AllUsersDesktop")
Set oUrlLink = objShell.CreateShortcut(strDesktop+"\Microsoft Web Site.URL")
oUrlLink.TargetPath = "http://www.microsoft.com"
oUrlLink.Save

' https://ss64.com/vb/special.html
' https://support.microsoft.com/en-us/help/244677/how-to-create-a-desktop-shortcut-with-the-windows-script-host
' https://ss64.com/vb/echo.html

