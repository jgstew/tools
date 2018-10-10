@echo off
REM https://ss64.com/nt/for_cmd.html

set _cmdstr=certutil -p [password] -dump cert.p12

for /f "tokens=2" %%a in (
 '%_cmdstr% ^|find "NotAfter:"'
) do (
 set RESULT=%%a
)

echo expration: %RESULT%
