:<<"::CMDLITERAL"
@ECHO OFF
REM Short link: http://bit.ly/installbigfix
REM  Usage: 
REM powershell -command "& { (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/jgstew/tools/master/CMD/install_bigfix.bat', 'install_bigfix.bat') }" -ExecutionPolicy Bypass
REM install_bigfix.bat __FQDN_OF_ROOT_OR_RELAY__

REM    Source: https://github.com/jgstew/tools/blob/master/CMD/install_bigfix.bat
REM   Related: https://github.com/jgstew/tools/blob/master/bash/install_bigfix.sh

REM http://stackoverflow.com/questions/2541767/what-is-the-proper-way-to-test-if-variable-is-empty-in-a-batch-file-if-not-1
IF [%1] == [] ECHO please provide FQDN for root or relay && EXIT /B
REM KNOWN ISSUE: if enhanced security is enabled on root/relay, then must use HTTPS for masthead download. This will mean that the download part will have to ignore SSL errors
SET MASTHEADURL=http://%1:52311/masthead/masthead.afxm
SET RELAYFQDN=%1
SET BASEFOLDER=C:\Windows\Temp

REM check if BigFix is installed
sc query besclient | find /I "besclient" > nul
if %errorlevel% NEQ 1 goto end
REM if errorlevel = 1 then BigFix is NOT installed, so continue:

REM  TODO: handle clientsettings.cfg or masthead.afxm or actionsite.afxm already in the CWD
REM  TODO: check for admin rights http://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights

REM http://stackoverflow.com/questions/4781772/how-to-test-if-an-executable-exists-in-the-path-from-a-windows-batch-file
where /q powershell || ECHO Cound not find powershell. && EXIT /B

@ECHO ON
REM this following line will need to ignore SSL errors if HTTPS is used instead of HTTP
powershell -command "& { (New-Object Net.WebClient).DownloadFile('%MASTHEADURL%', '%BASEFOLDER%\actionsite.afxm') }" -ExecutionPolicy Bypass
powershell -command "& { (New-Object Net.WebClient).DownloadFile('http://software.bigfix.com/download/bes/95/BigFix-BES-Client-9.5.9.62.exe', '%BASEFOLDER%\BESClient.exe') }" -ExecutionPolicy Bypass
@ECHO OFF

REM https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Tivoli%20Endpoint%20Manager/page/Configuration%20Settings
REM https://gist.github.com/jgstew/51a99ab4b5997efa0318
REM http://stackoverflow.com/questions/1702762/how-to-create-an-empty-file-at-the-command-line-in-windows
REM http://stackoverflow.com/questions/7225630/how-to-echo-2-no-quotes-to-a-file-from-a-batch-script
type NUL > %BASEFOLDER%\clientsettings.cfg
REM  TODO: only do the following line if FQDN_variable is set
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_RelaySelect_FailoverRelay=http://%1:52311/bfmirror/downloads/
>>%BASEFOLDER%\clientsettings.cfg ECHO __RelaySelect_Automatic=1
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Resource_StartupNormalSpeed=1
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Download_RetryMinutes=1
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Resource_WorkIdle=20
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Resource_SleepIdle=500
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Comm_CommandPollEnable=1
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Comm_CommandPollIntervalSeconds=10800
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Log_Days=30
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Download_UtilitiesCacheLimitMB=500
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Download_DownloadsCacheLimitMB=5000
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Download_MinimumDiskFreeMB=2000

ECHO
ECHO %0
ECHO %1
ECHO %MASTHEADURL%
ECHO
ECHO Installing BigFix now.
%BASEFOLDER%\BESClient.exe /s /v"/l*voicewarmup %BASEFOLDER%\install_bigfix.log /qn"

:end
EXIT /B
::CMDLITERAL
