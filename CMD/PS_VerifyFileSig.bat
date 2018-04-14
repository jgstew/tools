
powershell -ExecutionPolicy Bypass -command "(Get-AuthenticodeSignature \"C:\Temp\CatalogPC.cab\").Status -eq 'Valid'"
