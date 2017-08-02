
' zipGetFilesList.vbs
' Written by James Stewart ( @jgstew )
' Public Domain - use at your own risk
Dim strZipFilePath, objShell, objFiles, objCurrentFolder

' http://blogs.technet.com/b/heyscriptingguy/archive/2006/04/05/how-can-i-determine-the-path-to-the-folder-where-a-script-is-running.aspx
' http://stackoverflow.com/questions/4200028/vbscript-list-all-pdf-files-in-folder-and-subfolders
Set objCurrentFolder = CreateObject("Scripting.FileSystemObject").GetFolder( CreateObject("Wscript.Shell").CurrentDirectory )

' https://technet.microsoft.com/en-us/library/ee156618.aspx
If 1 = WScript.Arguments.Unnamed.Count Then
	strZipFilePath = WScript.Arguments.Unnamed.Item(0)
Else
	' operating on an ZIP in the current folder ( if there are multiple, the last one will be used )
	For Each objFile in objCurrentFolder.Files
		If UCase( CreateObject("Scripting.FileSystemObject").GetExtensionName(objFile.name)) = "ZIP" Then
			strZipFilePath = objFile.Path
		End If
	Next
	
	If IsEmpty( strZipFilePath ) Then
		Wscript.Echo
		Wscript.Echo "-ERROR-"
		Wscript.Echo "  Usage: zipGetFilesList.vbs ""PATH\TO\FILE.ZIP"" "
		Wscript.Quit
	End If
End If

Wscript.Echo strZipFilePath

Set objShell = CreateObject( "Shell.Application" )

Set objFiles = objShell.NameSpace( strZipFilePath ).Items( )

For Each item in objFiles
    WScript.Echo item
Next
