@ECHO OFF
REM Downloads and runs powershell/install_bigfix.ps1 against the relay set below.
REM Intended for OEM / first-boot use. Requires admin. Kept PS 2.0 / Win7 compatible.
REM
REM Edit RELAY (and optionally RELAY_PASSWORD) before shipping this image.

SET "RELAY=relay.example.com"
SET "RELAY_PASSWORD="

SET "SCRIPT_URL=https://raw.githubusercontent.com/jgstew/tools/master/powershell/install_bigfix.ps1"
SET "SCRIPT_PATH=%WINDIR%\Temp\install_bigfix.ps1"

ECHO Downloading: %SCRIPT_URL%
powershell -ExecutionPolicy Bypass -Command "(New-Object Net.WebClient).DownloadFile('%SCRIPT_URL%', '%SCRIPT_PATH%')"
IF NOT EXIST "%SCRIPT_PATH%" (
    ECHO ERROR: Failed to download %SCRIPT_URL%
    EXIT /B 1
)

ECHO Running: %SCRIPT_PATH% %RELAY%
powershell -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" "%RELAY%" "%RELAY_PASSWORD%"
EXIT /B %ERRORLEVEL%
