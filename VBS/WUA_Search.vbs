
' This script determines what updates are applicable on a Windows machine using the WUA api.
' Source: https://msdn.microsoft.com/en-us/library/windows/desktop/aa387102(v=vs.85).aspx

Set updateSession = CreateObject("Microsoft.Update.Session")
updateSession.ClientApplicationID = "Check for Windows Updates"

Set updateSearcher = updateSession.CreateUpdateSearcher()

' Method: https://msdn.microsoft.com/en-us/library/windows/desktop/aa386526(v=vs.85).aspx
Set searchResult = _
updateSearcher.Search("IsInstalled=0")

WScript.Echo "[Windows Updates]" & vbCRLF & "Number= " & searchResult.Updates.Count
            
For I = 0 To searchResult.Updates.Count-1
    Set update = searchResult.Updates.Item(I)
                WScript.Echo "Title" & I + 1 & "= " & update.Title
Next

' Related: https://thwack.solarwinds.com/community/application-and-server_tht/patchzone/blog/2012/10/05/how-the-windows-update-agent-determines-the-status-of-an-update
