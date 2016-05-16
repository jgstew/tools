:<<"::CMDLITERAL"
@ECHO OFF
SET MASTHEADURL=http://%1:52311/masthead/masthead.afxm
SET BASEFOLDER=C:\Windows\Temp
ECHO

REM http://stackoverflow.com/questions/4781772/how-to-test-if-an-executable-exists-in-the-path-from-a-windows-batch-file
where /q powershell || ECHO Cound not find powershell. && EXIT /B

powershell -command "& { (New-Object Net.WebClient).DownloadFile('http://software.bigfix.com/download/bes/95/BigFix-BES-Client-9.5.1.9.exe', 'c:\Windows\Temp\BESClient.exe') }" -ExecutionPolicy Bypass
powershell -command "& { (New-Object Net.WebClient).DownloadFile('%MASTHEADURL%', 'c:\Windows\Temp\actionsite.afxm') }" -ExecutionPolicy Bypass

REM https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Tivoli%20Endpoint%20Manager/page/Configuration%20Settings
REM https://gist.github.com/jgstew/51a99ab4b5997efa0318
ECHO NUL > C:\Windows\Temp\clientsettings.cfg
ECHO _BESClient_RelaySelect_FailoverRelay=http://%1:port/bfmirror/downloads/ >> C:\Windows\Temp\clientsettings.cfg
ECHO _BESClient_Resource_StartupNormalSpeed=1 >> C:\Windows\Temp\clientsettings.cfg
ECHO _BESClient_Download_RetryMinutes=1 >> C:\Windows\Temp\clientsettings.cfg
ECHO _BESClient_Resource_WorkIdle=20 >> C:\Windows\Temp\clientsettings.cfg
ECHO _BESClient_Resource_SleepIdle=500 >> C:\Windows\Temp\clientsettings.cfg
ECHO _BESClient_Comm_CommandPollEnable=1 >> C:\Windows\Temp\clientsettings.cfg
ECHO _BESClient_Comm_CommandPollIntervalSeconds=10800 >> C:\Windows\Temp\clientsettings.cfg
ECHO _BESClient_Log_Days=30 >> C:\Windows\Temp\clientsettings.cfg
ECHO _BESClient_Download_UtilitiesCacheLimitMB=500 >> C:\Windows\Temp\clientsettings.cfg
ECHO _BESClient_Download_DownloadsCacheLimitMB=5000 >> C:\Windows\Temp\clientsettings.cfg
ECHO _BESClient_Download_MinimumDiskFreeMB=2000 >> C:\Windows\Temp\clientsettings.cfg

ECHO I am %COMSPEC%
ECHO put CMD/BAT lines in here.
ECHO %0
ECHO %1
ECHO %MASTHEADURL%

PAUSE
EXIT
::CMDLITERAL
