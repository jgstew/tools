
REM https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/certutil#BKMK_importPFX

certutil -f -p [password] -dump "cert.p12"

REM TODO: validate expiration above

certutil -f -p [password] -importpfx "cert.p12"

