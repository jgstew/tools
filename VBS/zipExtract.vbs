
' zipExtract.vbs
' Written by James Stewart ( @jgstew )
' Public Domain - use at your own risk
Const NOCONFIRMATION = &H10&
Const NOERRORUI = &H400&
Const SIMPLEPROGRESS = &H100&
 
cFlags = NOCONFIRMATION + NOERRORUI + SIMPLEPROGRESS

' Dim to declare variables isn't required in VBScript except to make them available across all procedures within the script
Dim strZipFilePath, objOutputFolder, objCurrentFolder, objFSO, objShell

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject( "Shell.Application" )

' http://blogs.technet.com/b/heyscriptingguy/archive/2006/04/05/how-can-i-determine-the-path-to-the-folder-where-a-script-is-running.aspx
' http://stackoverflow.com/questions/4200028/vbscript-list-all-pdf-files-in-folder-and-subfolders
Set objCurrentFolder = objFSO.GetFolder( CreateObject("Wscript.Shell").CurrentDirectory )

' https://technet.microsoft.com/en-us/library/ee156618.aspx
If 1 = WScript.Arguments.Unnamed.Count Then
	strZipFilePath = WScript.Arguments.Unnamed.Item(0)
Else
	' operating on an ZIP in the current folder ( if there are multiple, the last one will be used )
	For Each objFile in objCurrentFolder.Files
		If UCase( objFSO.GetExtensionName(objFile.name)) = "ZIP" Then
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
	objOutputFolder = objFSO.GetAbsolutePathName( WScript.Arguments.Named.Item("OutDir") )
Else
	objOutputFolder = objCurrentFolder
End If

' TODO: Check to make sure output directory exists!

'  Extract the Files:
' https://asmand.wordpress.com/2015/06/15/unzip-with-vbscript/
' https://www.symantec.com/connect/forums/vbscript-extract-zip
objShell.NameSpace( objOutputFolder ).copyHere ( objShell.NameSpace( objFSO.GetAbsolutePathName( strZipFilePath ) ).Items() ), cFlags
