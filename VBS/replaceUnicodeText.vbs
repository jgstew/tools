' VBScript to replace text within a Unicode Text file
' adapted from https://blogs.technet.microsoft.com/heyscriptingguy/2005/02/08/how-can-i-find-and-replace-text-in-a-text-file/
' original source: https://gist.github.com/jgstew/504e2d85b2a6f87ab8af727e161f2b70
Const ForReading = 1
Const ForWriting = 2
Const ForAppending = 8

' https://msdn.microsoft.com/en-us/library/314cz14s(VS.85).aspx
Const TristateTrue = -1  'Opens the file as Unicode.

strFileName = Wscript.Arguments(0)
strOldText = Wscript.Arguments(1)
strNewText = Wscript.Arguments(2)

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile(strFileName, ForReading, FALSE, TristateTrue)

strText = objFile.ReadAll

objFile.Close

strNewText = Replace(strText, strOldText, strNewText)

Set objFile = objFSO.OpenTextFile(strFileName, ForWriting, FALSE, TristateTrue)
objFile.WriteLine strNewText
objFile.Close
