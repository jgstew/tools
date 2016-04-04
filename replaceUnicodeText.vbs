Const ForReading = 1
Const ForWriting = 2

strFileName = Wscript.Arguments(0)
strOldText = Wscript.Arguments(1)
strNewText = Wscript.Arguments(2)


Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile(strFileName, ForReading)
Do Until objFile.AtEndOfStream
    strLine= objFile.ReadLine
    Wscript.Echo strLine
Loop
objFile.Close



'Wscript.Echo strText

'strNewText = Replace(strText, strOldText, strNewText)


'Set objFile2 = objFSO.OpenTextFile(strFileName, ForWriting)
'objFile2.WriteLine strNewText
'objFile2.Close