
REM work in progress
REM Setup a non-production BigFix Eval Server with SQL Developer Edition.

REM http://software.bigfix.com/download/bes/95/BigFix-BES-9.5.9.62.exe
REM http://download.microsoft.com/download/2/5/0/2508F7B4-6DDE-4C3E-B1FA-E1EB66F2F79F/SQLServer2016-SSEI-Dev.exe

SET BASEFOLDER=C:\tmp

REM Make folder if not existing:  https://stackoverflow.com/questions/4165387/create-folder-with-batch-but-only-if-it-doesnt-already-exist
if not exist "%BASEFOLDER%" mkdir %BASEFOLDER%

REM Open folder:
start "" %BASEFOLDER%


REM https://github.com/jgstew/bigfix-content/blob/master/fixlet/Install%20SQL%20Server%20Management%20Studio%2016.5.1%20-%20Windows.bes
REM Download SQL Server Management Studio:
start "" powershell -command "& { (New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/f/e/b/feb0e6be-21ce-4f98-abee-d74065e32d0a/SSMS-Setup-ENU.exe', '%BASEFOLDER%\SSMS-Setup-ENU.exe') }" -ExecutionPolicy Bypass


REM Download BigFix Root Server:
start "" powershell -command "& { (New-Object Net.WebClient).DownloadFile('http://software.bigfix.com/download/bes/100/BigFix-BES-10.0.0.133.exe', '%BASEFOLDER%\BigFix-BES.exe') }" -ExecutionPolicy Bypass

REM Download BigFix Fixlet Debugger:
REM http://software.bigfix.com/download/bes/100/util/QNA10.0.0.133.zip
start "" powershell -command "& { (New-Object Net.WebClient).DownloadFile('http://software.bigfix.com/download/bes/100/util/QNA10.0.0.133.zip', '%BASEFOLDER%\BigFix-FixletDebugger.zip') }" -ExecutionPolicy Bypass

REM Download SQLServer Developer Edition:
powershell -command "& { (New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/5/A/7/5A7065A2-C81C-4A31-9972-8A31AC9388C1/SQLServer2017-SSEI-Dev.exe', '%BASEFOLDER%\SQLServer-SSEI-Dev.exe') }" -ExecutionPolicy Bypass
REM Install SQLServer Developer Edition:
REM https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-2017
REM Download Commnad:
%BASEFOLDER%\SQLServer-SSEI-Dev.exe /MEDIAPATH="%BASEFOLDER%" /ACTION=Download /LANGUAGE=en-US /MEDIATYPE=CAB /QUIET

REM Install Command: (interactive)
%BASEFOLDER%\SQLServer-SSEI-Dev.exe /ACTION=Install /MEDIAPATH=C:\tmp /IACCEPTSQLSERVERLICENSETERMS /LANGUAGE=en-US

REM https://download.microsoft.com/download/0/5/B/05B2AF8F-906F-4C57-A58E-5780F64F9D62/SSMS-Setup-ENU.exe
REM Install SQL Server Management Studio:
%BASEFOLDER%\SSMS-Setup-ENU.exe /install /quiet /norestart


REM press any key to continue....
pause

REM  TODO: configure SQL SA account?
REM  TODO: configure SQL login from AD account / local win admin account?
REM  TODO: open firewall for MSSQL to local subnet ?
REM  TODO: open firewall for BigFix to local subnet+ ?
REM  TODO: create local MO account
REM  TODO: BES Admin: create BES Admin Password
REM  TODO: BES Admin: set recommended BES Admin Settings
REM  TODO: BES Admin: create encryption keys for client encryption in BES Admin
REM  TODO: BES Admin: schedule BES Property ID Mapper
REM  TODO: configure REST API creds - Web Reports - etc
REM  TODO: create custom site(s) `Shared` `Dashboards` `Private`
REM  TODO: create roles 
REM  TODO: enable sites, subscribe computers
REM  TODO: install adobe flash for IE for root or console systems (DISM)
REM  TODO: setup download plugins
REM  TODO: 
