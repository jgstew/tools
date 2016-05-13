:<<"::CMDLITERAL"
@ECHO OFF
SET MASTHEADURL=http://%1:52311/masthead/masthead.afxm
ECHO

bitsadmin /transfer bigfixdl%random% /download /priority FOREGROUND http://software.bigfix.com/download/bes/95/BigFix-BES-Client-9.5.1.9.exe C:\Windows\Temp\bigfixclient.exe
bitsadmin /transfer bigfixcfgdl%random% /download /priority FOREGROUND %MASTHEADURL% C:\Windows\Temp\masthead.afxm

ECHO I am %COMSPEC%
ECHO put CMD/BAT lines in here.
ECHO %0
ECHO %1
ECHO %MASTHEADURL%

PAUSE
EXIT
::CMDLITERAL
