
# Tested in PowerShell 5.1 & PowerShell Core 6.0.2 on Windows 10
# Usecase: trigger BigFix UI with desktop shortcut, but if done too soon, BigFix won't be started and an error will be displayed without this script.

# Uncomment following line to disable write-host output to console:
# function global:Write-Host() {}


# https://stackoverflow.com/questions/28186904/powershell-wait-for-service-to-be-stopped-or-started
$service = "BESClient"
$timeWait = "00:02:00"
$status = "Running" # change to Stopped if you want to wait for services to start

write-host "Waiting for BESClient Service to be ready (up to" ($timeWait) "max)"

# http://www.powershellmagazine.com/2013/04/10/pstip-wait-for-a-service-to-reach-a-specified-status/
$svc = (Get-Service $service)
$svc.WaitForStatus($status,$timeWait)
$bDesiredState = ($svc | ? {$_.status -eq $status})

write-host "BESClient Status: " $svc.status

if ($bDesiredState)
{
    # add slight delay in case service just started
    sleep -Milliseconds 500

    # https://stackoverflow.com/questions/31879814/check-if-a-file-exists-or-not-in-windows-powershell
    # if SSA, open SSA:    C:\Program Files (x86)\BigFix Enterprise\BigFix Self Service Application\BigFixSSA.exe
    if (Test-Path "C:\Program Files (x86)\BigFix Enterprise\BigFix Self Service Application\BigFixSSA.exe" -PathType Leaf)
    {
        write-host "Opening SSA"
        Start-Process -FilePath "C:\Program Files (x86)\BigFix Enterprise\BigFix Self Service Application\BigFixSSA.exe"
    }
    # else open ClientUI:  C:\Program Files (x86)\BigFix Enterprise\BES Client\TriggerClientUI.exe
    ElseIf (Test-Path "C:\Program Files (x86)\BigFix Enterprise\BES Client\TriggerClientUI.exe" -PathType Leaf)
    {
        write-host "Opening ClientUI"
        Start-Process -FilePath "C:\Program Files (x86)\BigFix Enterprise\BES Client\TriggerClientUI.exe"
        # ideally get this location dynamically: (would need the following but in PowerShell)
        # unique values of pathnames of (folder it) of (it as string as trimmed string) of (values "InstallLocation" of keys whose(value "DisplayName" of it as string contains "BigFix Client") of keys "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" of registry ; values "EnterpriseClientFolder" of keys "HKEY_LOCAL_MACHINE\SOFTWARE\BigFix\EnterpriseClient" of registry )
    }
    Else
    {
        write-host "Couldn't Find BigFix UI EXEs"
    }
}

write-host "Finished"

# don't exit too quickly (useful if invoked by shortcut)
sleep -Milliseconds 800
