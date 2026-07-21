<#
.SYNOPSIS
    Disables all startup apps for all users via the Task Manager StartupApproved registry keys.

.DESCRIPTION
    Iterates through all user profile registry hives and sets each startup app entry
    under StartupApproved\Run and StartupApproved\Run32 to the disabled state.
    Must be run as Administrator.

.NOTES
    The disabled byte array (0x03,...) tells Task Manager the entry is disabled.
    The enabled byte array starts with 0x02.
#>

$DisabledValue = [byte[]](0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)

$StartupPaths = @(
    "Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
    "Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
)

# Load the HKU registry hive if not already available
if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
}

# Get all user SIDs (skip well-known short SIDs and _Classes keys)
$UserSIDs = Get-ChildItem -Path "HKU:\" |
    Where-Object { $_.PSChildName -match '^S-1-5-21-' -and $_.PSChildName -notmatch '_Classes$' } |
    Select-Object -ExpandProperty PSChildName

foreach ($SID in $UserSIDs) {
    foreach ($StartupPath in $StartupPaths) {
        $FullPath = "HKU:\$SID\$StartupPath"

        if (-not (Test-Path $FullPath)) {
            continue
        }

        $Key = Get-Item -Path $FullPath
        $AppNames = $Key.GetValueNames() | Where-Object { $_ -ne "" }

        foreach ($AppName in $AppNames) {
            Write-Host "Disabling startup app '$AppName' for SID: $SID"
            Set-ItemProperty -Path $FullPath -Name $AppName -Value $DisabledValue
        }
    }
}

Write-Host "`nAll startup apps have been disabled for all users."
