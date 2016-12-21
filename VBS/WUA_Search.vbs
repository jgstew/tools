
' This script determines what updates are applicable on a Windows machine using the WUA api.
' Source: https://msdn.microsoft.com/en-us/library/windows/desktop/aa387102(v=vs.85).aspx

Set updateSession = CreateObject("Microsoft.Update.Session")
updateSession.ClientApplicationID = "MSDN Sample Script"

Set updateSearcher = updateSession.CreateUpdateSearcher()

WScript.Echo "Searching for updates..." & vbCRLF

Set searchResult = _
updateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")

WScript.Echo "List of applicable items on the machine:"

For I = 0 To searchResult.Updates.Count-1
    Set update = searchResult.Updates.Item(I)
    WScript.Echo I + 1 & "> " & update.Title
Next

If searchResult.Updates.Count = 0 Then
    WScript.Echo "There are no applicable updates."
    WScript.Quit
End If

' Related: https://thwack.solarwinds.com/community/application-and-server_tht/patchzone/blog/2012/10/05/how-the-windows-update-agent-determines-the-status-of-an-update
