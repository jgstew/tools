
powershell -ExecutionPolicy Bypass -command "(Get-AuthenticodeSignature \"C:\Temp\CatalogPC.cab\").Status -eq 'Valid'"

REM https://stackoverflow.com/a/19876949
REM https://linux.die.net/man/1/chktrust
REM http://manpages.ubuntu.com/manpages/trusty/man1/chktrust.1.html
