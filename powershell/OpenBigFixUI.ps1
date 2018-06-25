
# Tested in PowerShell Core 6.0.2 on Windows 10
# https://stackoverflow.com/questions/28186904/powershell-wait-for-service-to-be-stopped-or-started

$services = "BESClient"
$maxRepeat = 120
$status = "Running" # change to Stopped if you want to wait for services to start

do
{
    $bDesiredState = (Get-Service $services | ? {$_.status -eq $status})
    $maxRepeat--
    if ( !($bDesiredState))
    {
        sleep -Milliseconds 1000
    }
} until ($bDesiredState -or $maxRepeat -eq 0)

write-host "BESClient Status: " (Get-Service $services).status

if($bDesiredState)
{
    # https://stackoverflow.com/questions/31879814/check-if-a-file-exists-or-not-in-windows-powershell
    # if SSA, open SSA:    C:\Program Files (x86)\BigFix Enterprise\BigFix Self Service Application\BigFixSSA.exe
    if(Test-Path "C:\Program Files (x86)\BigFix Enterprise\BigFix Self Service Application\BigFixSSA.exe" -PathType Leaf)
    {
        write-host "Opening SSA"
    }
    # else open ClientUI:  C:\Program Files (x86)\BigFix Enterprise\BES Client\TriggerClientUI.exe
    if(Test-Path "C:\Program Files (x86)\BigFix Enterprise\BES Client\TriggerClientUI.exe" -PathType Leaf)
    {
        write-host "Opening ClientUI"
    }
}

