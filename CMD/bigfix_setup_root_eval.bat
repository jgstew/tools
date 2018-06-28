
REM work in progress
REM Setup a non-production BigFix Eval Server with SQL Developer Edition.

REM http://software.bigfix.com/download/bes/95/BigFix-BES-Server-9.5.9.62.exe
REM http://download.microsoft.com/download/2/5/0/2508F7B4-6DDE-4C3E-B1FA-E1EB66F2F79F/SQLServer2016-SSEI-Dev.exe

SET BASEFOLDER=C:\Windows\Temp

REM Download SQLServer Developer Edition:
powershell -command "& { (New-Object Net.WebClient).DownloadFile('http://download.microsoft.com/download/2/5/0/2508F7B4-6DDE-4C3E-B1FA-E1EB66F2F79F/SQLServer2016-SSEI-Dev.exe', '%BASEFOLDER%\SQLServer-SSEI-Dev.exe') }" -ExecutionPolicy Bypass
REM Install SQLServer Developer Edition:
REM https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-2017
%BASEFOLDER%\SQLServer-SSEI-Dev.exe /Q /ACTION=Install /IACCEPTSQLSERVERLICENSETERMS /MEDIAPATH="%BASEFOLDER%\SQLServerMedia"


REM https://github.com/jgstew/bigfix-content/blob/f36708ebf7af38f84a286f3b79131faccb1d2e9c/fixlet/Install%20SQL%20Server%20Management%20Studio%2016.5.1%20-%20Windows.bes
REM Download SQL Server Management Studio:
powershell -command "& { (New-Object Net.WebClient).DownloadFile('https://download.microsoft.com/download/0/5/B/05B2AF8F-906F-4C57-A58E-5780F64F9D62/SSMS-Setup-ENU.exe', '%BASEFOLDER%\SSMS-Setup-ENU.exe') }" -ExecutionPolicy Bypass
REM https://download.microsoft.com/download/0/5/B/05B2AF8F-906F-4C57-A58E-5780F64F9D62/SSMS-Setup-ENU.exe
REM Install SQL Server Management Studio:
%BASEFOLDER%\SSMS-Setup-ENU.exe /install /quiet /norestart

REM for some reason, this didn't create a start menu shortcut it seems for SQL Server Management Studio


REM Download BigFix Root Server:
REM powershell -command "& { (New-Object Net.WebClient).DownloadFile('http://software.bigfix.com/download/bes/95/BigFix-BES-Server-9.5.9.62.exe', '%BASEFOLDER%\BigFix-BES-Server.exe') }" -ExecutionPolicy Bypass
REM Install:
REM %BASEFOLDER%\BigFix-BES-Server.exe
