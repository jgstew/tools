
' zipExtract.vbs
' Written by James Stewart ( @jgstew )
' Public Domain - use at your own risk
Const NOCONFIRMATION = &H10&
Const NOERRORUI = &H400&
Const SIMPLEPROGRESS = &H100&
 
cFlags = NOCONFIRMATION + NOERRORUI + SIMPLEPROGRESS

Dim strZipFilePath, objOutputFolder, objCurrentFolder

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
		Wscript.Echo "  Usage: zipGetFilesList.vbs ""PATH\TO\FILE.ZIP""  [/OutDir:OutputDirectoryPath]"
		Wscript.Quit
	End If
End If

' output zip file path (debugging)
'Wscript.Echo strZipFilePath

' http://stackoverflow.com/questions/4100506/check-if-an-object-exists-in-vbscript
'If WScript.Arguments.Named.Count = 1 Then
If NOT IsEmpty( WScript.Arguments.Named.Item("OutDir") ) Then
	objOutputFolder = CreateObject("Scripting.FileSystemObject").GetAbsolutePathName( WScript.Arguments.Named.Item("OutDir") )
Else
	objOutputFolder = objCurrentFolder
End If

'  Extract the Files:
' https://asmand.wordpress.com/2015/06/15/unzip-with-vbscript/
' https://www.symantec.com/connect/forums/vbscript-extract-zip
CreateObject("Shell.Application").NameSpace( objOutputFolder ).copyHere ( CreateObject( "Shell.Application" ).NameSpace( CreateObject("Scripting.FileSystemObject").GetAbsolutePathName( strZipFilePath ) ).Items() ), cFlags
