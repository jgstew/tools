
REM work in progress
REM Setup a non-production BigFix Eval Server with SQL Developer Edition.

REM http://software.bigfix.com/download/bes/95/BigFix-BES-Server-9.5.9.62.exe
REM http://download.microsoft.com/download/2/5/0/2508F7B4-6DDE-4C3E-B1FA-E1EB66F2F79F/SQLServer2016-SSEI-Dev.exe

SET BASEFOLDER=C:\Windows\Temp

powershell -command "& { (New-Object Net.WebClient).DownloadFile('http://download.microsoft.com/download/2/5/0/2508F7B4-6DDE-4C3E-B1FA-E1EB66F2F79F/SQLServer2016-SSEI-Dev.exe', '%BASEFOLDER%\SQLServer-SSEI-Dev.exe') }" -ExecutionPolicy Bypass

