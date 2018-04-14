
powershell -ExecutionPolicy Bypass -command "(Get-AuthenticodeSignature \"C:\Temp\CatalogPC.cab\").Status -eq 'Valid'"

REM https://stackoverflow.com/a/19876949
