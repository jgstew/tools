'VBScript to add a file to zip file

Dim fso, objShell, zipFile

Set fso = CreateObject("Scripting.FileSystemObject")

strZipFilePath = fso.GetAbsolutePathName("example.zip")
strInputFile = fso.GetAbsolutePathName("..\LICENSE")

Function FileExists(FilePath)  
  If fso.FileExists(FilePath) Then
    FileExists=CBool(1)
  Else
    FileExists=CBool(0)
  End If
End Function

If NOT FileExists(strZipFilePath) Then
    'Create empty ZIP file.
    CreateObject("Scripting.FileSystemObject").CreateTextFile(strZipFilePath, True).Write "PK" & Chr(5) & Chr(6) & String(18, vbNullChar)
    'WScript.Sleep 100
End If

Set objShell = CreateObject("Shell.Application")

Set zipFile = objShell.NameSpace(strZipFilePath)

cntItems = zipFile.Items.Count + 1

zipFile.CopyHere(strInputFile)

While zipFile.Items.Count < cntItems
    WScript.Sleep 100
Wend

' Clean up
Set objShell = nothing
Set fso = nothing
Set zipFile = nothing
