
REM https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/certutil#BKMK_importPFX

certutil -f -p [password] -dump "cert.p12"

REM get just expiration: https://github.com/jgstew/tools/blob/master/CMD/cert_file_expiration.bat

certutil -f -p [password] -importpfx "cert.p12"

