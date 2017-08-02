
' written by James Stewart  ( @jgstew )
' public domain, use at your own risk
' this vbs script will get msi property values
' the default is to get "ProductName"
' the default can be changed by renaming the file, or changing the initial msiProperty value
'    Example:  msiGetPropertyProductVersion.vbs will get ProductVersion
Const msiOpenDatabaseModeReadOnly = 0
Dim msiLib, db, view, msiPath, msiProperty, objCurrentFolder, myRegExp, matches

msiProperty = "ProductName"

'Prepare a regular expression object
Set myRegExp = New RegExp
myRegExp.IgnoreCase = True
myRegExp.Pattern = "msiGetProperty(\w).vbs"
Set matches = myRegExp.Execute( Wscript.ScriptName )

' set property retrieved based upon name of script
If 1 = matches.Count Then
	If 1 = matches.Item(0).SubMatches.Count Then
		msiProperty = myRegExp.Execute( Wscript.ScriptName ).Item(0).SubMatches(0)
	End If
End If

' http://blogs.technet.com/b/heyscriptingguy/archive/2006/04/05/how-can-i-determine-the-path-to-the-folder-where-a-script-is-running.aspx
' http://stackoverflow.com/questions/4200028/vbscript-list-all-pdf-files-in-folder-and-subfolders
Set objCurrentFolder = CreateObject("Scripting.FileSystemObject").GetFolder( CreateObject("Wscript.Shell").CurrentDirectory )

' https://technet.microsoft.com/en-us/library/ee156618.aspx
If 1 = WScript.Arguments.Unnamed.Count Then
	msiPath = WScript.Arguments.Unnamed.Item(0)
Else
	' operating on an MSI in the current folder ( if there are multiple, the last one will be used )
	For Each objFile in objCurrentFolder.Files
		If UCase( CreateObject("Scripting.FileSystemObject").GetExtensionName(objFile.name)) = "MSI" Then
			msiPath = objFile.Name
		End If
	Next
	
	If IsEmpty( msiPath ) Then
		Wscript.Echo
		Wscript.Echo "-ERROR-"
		Wscript.Echo "  Usage: msiGetProperty.vbs ""PATH\TO\FILE.MSI"" [/Property:NAME_OF_MSI_PROPERTY]"
		Wscript.Quit
	End If
End If

' http://stackoverflow.com/questions/4100506/check-if-an-object-exists-in-vbscript
'If WScript.Arguments.Named.Count = 1 Then
If NOT IsEmpty( WScript.Arguments.Named.Item("Property") ) Then
	msiProperty = WScript.Arguments.Named.Item("Property")
End If

Set msiLib = CreateObject("WindowsInstaller.Installer")
Set db = msiLib.OpenDataBase(msiPath, msiOpenDatabaseModeReadOnly)
Set view = db.OpenView("SELECT `Value` FROM `Property` WHERE `Property` = '" & msiProperty & "'")
view.Execute()

Wscript.Echo view.Fetch().StringData(1)
