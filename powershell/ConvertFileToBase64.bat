powershell -ExecutionPolicy Bypass -command "[convert]::ToBase64String((get-content 'setup.exe.ico' -encoding byte)) | set-content( 'setup.exe.ico.base64' )"
