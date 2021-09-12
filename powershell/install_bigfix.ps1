# To download:
#  (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/jgstew/tools/master/powershell/install_bigfix.ps1', "\Windows\temp\install_bigfix.ps1")
#  powershell -ExecutionPolicy Bypass .\install_bigfix.ps1 RELAY.FQDN


# adaption of this:  https://github.com/jgstew/tools/blob/master/CMD/install_bigfix.bat
#         see also:  https://github.com/jgstew/tools/blob/master/bash/install_bigfix.sh
# NOTE: This can be used to deploy BigFix automatically to an Azure Windows VM with a custom Azure script extension

# Run in C:\Windows\Temp by default
$BASEFOLDER=[System.Environment]::GetEnvironmentVariable('TEMP','Machine')

cd "$BASEFOLDER"

if (Get-Service -Name BESClient -ErrorAction SilentlyContinue)
{
    Write-Host "ERROR: BigFix is already installed!"
    Write-Host "Last 20 lines of newest log file:"
    Get-Content ("C:\Program Files (x86)\BigFix Enterprise\BES Client\__BESData\__Global\Logs\" + (Get-Date -format "yyyyMMdd") + ".log") -ErrorAction SilentlyContinue | select -Last 20
    # Number of errors in log:  (Get-Content ("C:\Program Files (x86)\BigFix Enterprise\BES Client\__BESData\__Global\Logs\"+ (Get-Date -format "yyyyMMdd") + ".log") -ErrorAction SilentlyContinue) -like "*error*" | measure | % { $_.Count }
    # Lines with errors in ALL bigfix client logs:  (Get-Content ("C:\Program Files (x86)\BigFix Enterprise\BES Client\__BESData\__Global\Logs\*.log") -ErrorAction SilentlyContinue) -like "*error*" | measure | % { $_.Count }
    Write-Host "Downloading: https://raw.githubusercontent.com/jgstew/tools/master/powershell/bigfix_uninstall_clean.ps1" 
    (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/jgstew/tools/master/powershell/bigfix_uninstall_clean.ps1', "$BASEFOLDER\bigfix_uninstall_clean.ps1")
    Exit 1
}

$RELAYFQDN=$args[0]

# Check if $RELAYFQDN is set
if ($RELAYFQDN.length -lt 2)
{
    Write-Host "ERROR: Must provide Relay FQDN as parameter"
    Exit -1
}

$MASTHEADURL="http://"+$RELAYFQDN+":52311/masthead/masthead.afxm"

Write-Host "Downloading: " $MASTHEADURL
(New-Object Net.WebClient).DownloadFile($MASTHEADURL, "$BASEFOLDER\actionsite.afxm")

# only continue if actionsite file exists
if ( -not (Test-Path "$BASEFOLDER\actionsite.afxm") )
{
    Write-Host "ERROR: actionsite file missing: $BASEFOLDER\actionsite.afxm"
    Exit -2
}

Write-Host "Downloading: https://software.bigfix.com/download/bes/100/BigFix-BES-Client-10.0.4.32.exe" 
(New-Object Net.WebClient).DownloadFile('https://software.bigfix.com/download/bes/100/BigFix-BES-Client-10.0.4.32.exe', "$BASEFOLDER\BESClient.exe")

# only continue if BESClient.exe file exists
if ( -not (Test-Path "$BASEFOLDER\BESClient.exe") )
{
    Write-Host "ERROR: BigFix Client Installer file missing: $BASEFOLDER\BESClient.exe"
    Exit -3
}

ECHO "_BESClient_RelaySelect_FailoverRelay=http://$($RELAYFQDN):52311/bfmirror/downloads/" >$BASEFOLDER\clientsettings.cfg
ECHO __RelaySelect_Automatic=1 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Resource_StartupNormalSpeed=1 >>$BASEFOLDER\clientsettings.cfg 
ECHO _BESClient_Download_RetryMinutes=1 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Download_CheckAvailabilitySeconds=120 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Resource_WorkIdle=20 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Resource_SleepIdle=500 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Resource_AccelerateForPendingMessage=1 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Comm_CommandPollEnable=1 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Comm_CommandPollIntervalSeconds=1800 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Log_Days=35 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Log_MaxSize=1536000 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Download_UtilitiesCacheLimitMB=500 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Download_DownloadsCacheLimitMB=5000 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Download_PreCacheStageDiskLimitMB=2000 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Download_PreCacheStageContinueWhenDiskLimited=1 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Download_MinimumDiskFreeMB=1000 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Comm_EnableConnectionTriggers=1 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Resource_AccelerateForPendingMessage=1 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_ActionManager_HistoryKeepDays=1095 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_ActionManager_HistoryDisplayDaysTech=90 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Download_FastHashVerify=1 >>$BASEFOLDER\clientsettings.cfg
ECHO _BESClient_Download_PreCacheStageContinueWhenDiskLimited=1 >>$BASEFOLDER\clientsettings.cfg
# ECHO _BESClient_Comm_ForceHttpsOnRelay=1 >>$BASEFOLDER\clientsettings.cfg

Write-Host "Installing BigFix now."
.\BESClient.exe /s /v"/l*voicewarmup $BASEFOLDER\install_bigfix.log /qn"

Write-Host "Waiting 15 Seconds"
Start-Sleep -Seconds 15

Write-Host "Last 20 lines of newest log file:"
Get-Content ("C:\Program Files (x86)\BigFix Enterprise\BES Client\__BESData\__Global\Logs\" + (Get-Date -format "yyyyMMdd") + ".log") -ErrorAction SilentlyContinue | select -Last 20

Exit 0
