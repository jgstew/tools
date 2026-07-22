# To download:
#  (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/jgstew/tools/master/powershell/install_bigfix.ps1', "\Windows\temp\install_bigfix.ps1")
#  powershell -ExecutionPolicy Bypass .\install_bigfix.ps1 RELAY.FQDN [RelayPassword]


# adaption of this:  https://github.com/jgstew/tools/blob/master/CMD/install_bigfix.bat
#         see also:  https://github.com/jgstew/tools/blob/master/bash/install_bigfix.sh
# NOTE: This can be used to deploy BigFix automatically to an Azure Windows VM with a custom Azure script extension
#
# Kept Windows 7 / PowerShell 2.0 compatible on purpose:
#   - uses Net.WebClient for downloads (no Invoke-WebRequest)
#   - avoids [CmdletBinding()] and other v3+ features
#   - here-strings, param() blocks, and Join-Path all work on PS 2.0

param(
    [string]$RelayFqdn  = $(if ($args.Count -ge 1) { $args[0] } else { $null }),
    [string]$RelayPassword = $(if ($args.Count -ge 2) { $args[1] } else { $null })
)

# These variables are used to determine which version of the BigFix agent should be downloaded.
# Keep in sync with bash/install_bigfix.sh (URLVERSION / URLMAJORMINOR).
#   Most recent version # found here under `Agent`: https://support.bigfix.com/bes/release/
$URLVERSION      = '11.0.6.137'
$URLMAJORMINOR   = ($URLVERSION -split '\.')[0..1] -join ''   # e.g. '11.0.6.137' -> '110'
$INSTALLERURL    = "https://software.bigfix.com/download/bes/$URLMAJORMINOR/BigFix-BES-Client-$URLVERSION.exe"

# Run in C:\Windows\Temp by default
$BASEFOLDER = [System.Environment]::GetEnvironmentVariable('TEMP','Machine')

$MastheadPath        = Join-Path $BASEFOLDER 'actionsite.afxm'
$InstallerPath       = Join-Path $BASEFOLDER 'BESClient.exe'
$ClientSettingsPath  = Join-Path $BASEFOLDER 'clientsettings.cfg'
$InstallLogPath      = Join-Path $BASEFOLDER 'install_bigfix.log'
$UninstallScriptPath = Join-Path $BASEFOLDER 'bigfix_uninstall_clean.ps1'
$BesClientLogDir     = 'C:\Program Files (x86)\BigFix Enterprise\BES Client\__BESData\__Global\Logs'
$TodaysLog           = Join-Path $BesClientLogDir ((Get-Date -Format 'yyyyMMdd') + '.log')

Set-Location $BASEFOLDER

if (Get-Service -Name BESClient -ErrorAction SilentlyContinue)
{
    Write-Host "Last 20 lines of newest log file:"
    Get-Content $TodaysLog -ErrorAction SilentlyContinue | Select-Object -Last 20

    Write-Host "INFO: BigFix is already installed!"
    # only download if file doesn't already exist:
    if (-not (Test-Path $UninstallScriptPath -PathType Leaf))
    {
        Write-Host "Downloading: https://raw.githubusercontent.com/jgstew/tools/master/powershell/bigfix_uninstall_clean.ps1"
        (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/jgstew/tools/master/powershell/bigfix_uninstall_clean.ps1', $UninstallScriptPath)
    }
    else
    {
        Write-Host "If needed, you can uninstall BigFix with: $UninstallScriptPath"
        Write-Host 'Tail the newest BigFix Client Log with: Get-Content ("C:\Program Files (x86)\BigFix Enterprise\BES Client\__BESData\__Global\Logs\" + (Get-Date -format "yyyyMMdd") + ".log") -ErrorAction SilentlyContinue -Tail 25 -Wait'
    }
    # Exit 0 so deployment systems treat "already installed" as success (idempotent).
    Exit 0
}

# Check if $RelayFqdn is set
if ([string]::IsNullOrWhiteSpace($RelayFqdn))
{
    Write-Host "ERROR: Must provide Relay FQDN as parameter"
    Exit 1
}

$MASTHEADURL = "http://" + $RelayFqdn + ":52311/masthead/masthead.afxm"

Write-Host "Downloading: $MASTHEADURL"
(New-Object Net.WebClient).DownloadFile($MASTHEADURL, $MastheadPath)

# only continue if actionsite file exists
if (-not (Test-Path $MastheadPath))
{
    Write-Host "ERROR: actionsite file missing: $MastheadPath"
    Exit 2
}

Write-Host "Downloading: $INSTALLERURL"
(New-Object Net.WebClient).DownloadFile($INSTALLERURL, $InstallerPath)

# only continue if BESClient.exe file exists
if (-not (Test-Path $InstallerPath))
{
    Write-Host "ERROR: BigFix Client Installer file missing: $InstallerPath"
    Exit 3
}

# Build clientsettings.cfg in one shot via a here-string (faster and easier to audit
# than the previous 20+ ECHO ... >> lines).
$ClientSettings = @"
_BESClient_RelaySelect_FailoverRelay=http://$($RelayFqdn):52311/bfmirror/downloads/
__RelaySelect_Automatic=1
_BESClient_Resource_StartupNormalSpeed=1
_BESClient_Download_RetryMinutes=1
_BESClient_Download_CheckAvailabilitySeconds=120
_BESClient_Resource_WorkIdle=20
_BESClient_Resource_SleepIdle=500
_BESClient_Resource_AccelerateForPendingMessage=1
_BESClient_Comm_CommandPollEnable=1
_BESClient_Comm_CommandPollIntervalSeconds=1800
_BESClient_Log_Days=35
_BESClient_Log_MaxSize=1536000
_BESClient_Download_UtilitiesCacheLimitMB=500
_BESClient_Download_DownloadsCacheLimitMB=5000
_BESClient_Download_PreCacheStageDiskLimitMB=2000
_BESClient_Download_PreCacheStageContinueWhenDiskLimited=1
_BESClient_Download_MinimumDiskFreeMB=1000
_BESClient_Comm_EnableConnectionTriggers=1
_BESClient_ActionManager_HistoryKeepDays=1095
_BESClient_ActionManager_HistoryDisplayDaysTech=90
_BESClient_Download_FastHashVerify=1
"@

if (-not [string]::IsNullOrWhiteSpace($RelayPassword))
{
    $ClientSettings += "`r`n_BESClient_SecureRegistration=$RelayPassword"
}

# _BESClient_Comm_ForceHttpsOnRelay=1

Set-Content -Path $ClientSettingsPath -Value $ClientSettings -Encoding ASCII

Write-Host "Installing BigFix now."
.\BESClient.exe /s /v"/l*voicewarmup $InstallLogPath /qn"

# Wait for the BESClient service to actually reach Running, instead of a blind sleep.
$deadline = (Get-Date).AddSeconds(120)
$svc = $null
while ((Get-Date) -lt $deadline)
{
    $svc = Get-Service -Name BESClient -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq 'Running') { break }
    Start-Sleep -Seconds 2
}

if (-not $svc)
{
    Write-Host "ERROR: BESClient service was not created. See install log: $InstallLogPath"
    Exit 4
}

if ($svc.Status -ne 'Running')
{
    Write-Host ("WARN: BESClient service exists but is '{0}', not 'Running'. Attempting Start-Service..." -f $svc.Status)
    Start-Service -Name BESClient -ErrorAction SilentlyContinue
    $svc.Refresh()
    if ($svc.Status -ne 'Running')
    {
        Write-Host ("ERROR: BESClient service failed to reach Running (current: {0})." -f $svc.Status)
        Exit 5
    }
}

Write-Host "BESClient service is Running."

Write-Host "Last 20 lines of newest log file:"
Get-Content $TodaysLog -ErrorAction SilentlyContinue | Select-Object -Last 20

Exit 0
