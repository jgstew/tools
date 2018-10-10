@echo off
REM https://ss64.com/nt/for_cmd.html

set _cmdstr=certutil -p [password] -dump cert.p12

for /f "tokens=2" %%a in (
 '%_cmdstr% ^|find "NotAfter:"'
) do (
 set RESULT=%%a
)

echo expration: %RESULT%

REM compare: https://stackoverflow.com/questions/17649235/compare-2-dates-in-a-windows-batch-file
