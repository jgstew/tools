
@echo off
Set Relevance=%*

REM https://stackoverflow.com/a/23328830/861745
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\BigFix\EnterpriseClient" /v EnterpriseClientFolder 2^>^&1^|find "REG_"') do @set sPath=%%b

echo %sPath%

echo %Relevance% | "%sPath%qna" -t -showtypes
