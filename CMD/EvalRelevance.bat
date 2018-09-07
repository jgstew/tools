REM @echo off
Set Relevance=%*

Set WoW=
REM https://superuser.com/a/321996/413576
REM https://stackoverflow.com/a/51502846/861745
REM  if x64 OS, then read x32 registry
if defined PROGRAMFILES(x86) Set WoW=\WOW6432Node

REM https://stackoverflow.com/a/23328830/861745
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE%WoW%\BigFix\EnterpriseClient" /v EnterpriseClientFolder 2^>^&1^|find "REG_"') do @set sPath=%%b

echo %Relevance% | "%sPath%qna" -t -showtypes
