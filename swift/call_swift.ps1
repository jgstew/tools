
# https://stackoverflow.com/questions/2124753/how-can-i-use-powershell-with-the-visual-studio-command-prompt

$env:BuildToolsFolder = Get-ItemProperty -Path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, InstallLocation | Where-Object { $_.DisplayName -match 'Visual Studio Build Tools' } | Select-Object InstallLocation | Select-Object -first 1 | Select-Object -ExpandProperty 'InstallLocation'
Push-Location $env:BuildToolsFolder
cmd /C "VC\Auxiliary\Build\vcvars64.bat&set" |
ForEach-Object {
    if ($_ -match "=") {
        $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
    }
}
Pop-Location

# output all env vars:
# Get-ChildItem env:

$env:INSTALLATION_DIR = "C:"
$env:OS = "windows"
$env:SDK = "C:\Library\Developer\Platforms\Windows.platform\Developer\SDKs\Windows.sdk"
$env:SDKROOT = "C:\Library\Developer\Platforms\Windows.platform\Developer\SDKs\Windows.sdk"

$env:SWIFTFLAGS = "-sdk $env:SDKROOT -resource-dir $env:SDKROOT\usr\lib\swift -I $env:SDKROOT\usr\lib\swift -L $env:SDKROOT\usr\lib\swift\windows -v"



CMD /C "C:\Library\Developer\Toolchains\unknown-Asserts-development.xctoolchain\usr\bin\swift.exe $env:SWIFTFLAGS $args"

Write-Output "Exit Code: $($LASTEXITCODE)"
