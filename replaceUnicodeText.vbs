Const ForReading = 1
Const ForWriting = 2

Const TristateTrue = -1  'Opens the file as Unicode.

strFileName = Wscript.Arguments(0)
strOldText = Wscript.Arguments(1)
strNewText = Wscript.Arguments(2)

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile(strFileName, ForReading, FALSE, TristateTrue)

strText = objFile.ReadAll

objFile.Close

strNewText = Replace(strText, strOldText, strNewText)

Set objFile = objFSO.OpenTextFile(strFileName, ForWriting)
objFile.WriteLine strNewText
objFile.Close