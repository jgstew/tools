
' Script invisible.vbs
' This can be used to run a BAT file invisibly as the current user
CreateObject("Wscript.Shell").Run """" & WScript.Arguments(0) & """", 0, False

' https://gallery.technet.microsoft.com/scriptcenter/de73a781-847d-499b-bbfd-d2d2c3ed288e
' http://stackoverflow.com/questions/5559081/running-a-bat-file-in-background-with-invisible-vbs-but-how-to-stop-it
' https://productforums.google.com/forum/#!topic/drive/v7ibbEPEsBc
