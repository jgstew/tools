
@call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
SET INSTALLATION_DIR=C:
SET OS=windows
SET SDK=C:\Library\Developer\Platforms\Windows.platform\Developer\SDKs\Windows.sdk
SET SDKROOT=C:\Library\Developer\Platforms\Windows.platform\Developer\SDKs\Windows.sdk

SET SWIFTFLAGS=-sdk %SDKROOT% -resource-dir %SDKROOT%\usr\lib\swift -I %SDKROOT%\usr\lib\swift -L %SDKROOT%\usr\lib\swift\windows -v

C:\Library\Developer\Toolchains\unknown-Asserts-development.xctoolchain\usr\bin\swift.exe %SWIFTFLAGS% %*

echo %ERRORLEVEL%
