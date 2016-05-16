:<<"::CMDLITERAL"
@ECHO OFF
SET MASTHEADURL=http://%1:52311/masthead/masthead.afxm
ECHO

REM http://stackoverflow.com/questions/4781772/how-to-test-if-an-executable-exists-in-the-path-from-a-windows-batch-file
where /q powershell || ECHO Cound not find powershell. && EXIT /B

powershell -command "& { (New-Object Net.WebClient).DownloadFile('http://software.bigfix.com/download/bes/95/BigFix-BES-Client-9.5.1.9.exe', 'c:\Windows\Temp\BESClient.exe') }" -ExecutionPolicy Bypass
powershell -command "& { (New-Object Net.WebClient).DownloadFile('%MASTHEADURL%', 'c:\Windows\Temp\masthead.afxm') }" -ExecutionPolicy Bypass

ECHO I am %COMSPEC%
ECHO put CMD/BAT lines in here.
ECHO %0
ECHO %1
ECHO %MASTHEADURL%

PAUSE
EXIT
::CMDLITERAL
