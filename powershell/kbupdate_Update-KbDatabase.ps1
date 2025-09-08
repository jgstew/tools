# https://github.com/potatoqualitee/kbupdate
# https://evotec.xyz/executing-hidden-or-private-functions-from-powershell-modules/

Write-Output "--- Start of script ---"

Write-Output "ERROR: This does not seem to work! The kbupdate module seems to be abandoned."
Write-Output "Exiting script."
Exit 1

# Ensure required modules are installed
$requiredModules = @('PSFramework', 'PSSQLite', 'kbupdate', 'kbupdate-library')
foreach ($module in $requiredModules) {
  if (-not (Get-Module -ListAvailable -Name $module)) {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Write-Output "Installing module: $module"
    Install-Module -Name $module -Force
  }
}

Write-Output ""
Write-Output "Loading kbupdate-library module..."
Import-Module kbupdate-library

$modpath = Split-Path (Get-Module kbupdate-library).Path | Select-Object -Last 1
$kblib = Join-PSFPath -Path $modpath -Child library
$db = Join-PSFPath -Path $kblib -Child kb.sqlite

Write-Output "Database path: $db"
Write-Output "Database exists: $(Test-Path $db)"
Write-Output "Database size: $((Get-Item $db).Length / 1MB) MB"

# write db path to GITHUB_ENV for use in other steps
if ($env:GITHUB_ENV) {
  Write-Output "Writing database path to GITHUB_ENV"
  "`$env:KBDATABASE=$db" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
}

Write-Output ""
Write-Output "Updating database..."
$Features = Import-Module -Name 'kbupdate' -PassThru -ErrorAction Stop
# Run private Update-KbDatabase command: (Windows Only)
& $Features { Update-KbDatabase -ErrorAction Stop }

Write-Output "Get new database size:"
Write-Output "Database size: $((Get-Item $db).Length / 1MB) MB"

Write-Output ""
Write-Output "--- End of script ---"
