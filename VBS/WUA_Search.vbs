
' This script determines what updates are applicable on a Windows machine using the WUA api.
' Usage: cscript WUA_Search.vbs //Nologo //B > Updates.ini
' Source: https://msdn.microsoft.com/en-us/library/windows/desktop/aa387102(v=vs.85).aspx

Set updateSession = CreateObject("Microsoft.Update.Session")
updateSession.ClientApplicationID = "Check for Windows Updates"

Set updateSearcher = updateSession.CreateUpdateSearcher()

' Method: https://msdn.microsoft.com/en-us/library/windows/desktop/aa386526(v=vs.85).aspx
Set searchResult = updateSearcher.Search("IsInstalled=0")

WScript.Echo "[Windows Updates]" & vbCRLF & "Number= " & searchResult.Updates.Count

numHidden = 0

For I = 0 To searchResult.Updates.Count-1
' IUpdate interface: https://msdn.microsoft.com/en-us/library/windows/desktop/aa386099(v=vs.85).aspx
    Set update = searchResult.Updates.Item(I)
    
    updateTypeStr = "Other"
    If 1=update.Type Then
        updateTypeStr = "Software"
    Else If 2=update.Type Then
        updateTypeStr = "Software"
    End If
    
    WScript.Echo updateTypeStr & I + 1 & "= " & update.Title
    
    If update.IsHidden Then
        numHidden = numHidden + 1
    End If
Next

WScript.Echo "Hidden= " & numHidden
' Related: https://thwack.solarwinds.com/community/application-and-server_tht/patchzone/blog/2012/10/05/how-the-windows-update-agent-determines-the-status-of-an-update
