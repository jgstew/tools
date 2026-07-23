Write-Host "This will make the computer unusable! DO NOT DO THIS UNLESS YOU ARE CERTAIN!"
[void]$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit

$bekPath = "C:\Windows\Temp\wipe.bek"
$log = "C:\Windows\Temp\wipe_blr.log"
$log_commands = "C:\Windows\Temp\wipe_blr_commands.log"
Start-Transcript -Path $log -Append
Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryKeyProtector -RecoveryKeyPath (Split-Path $bekPath)

# Get the new ExternalKey id and remove everything else
$vol = Get-BitLockerVolume -MountPoint "C:"
$keep = ($vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'ExternalKey' } | Select-Object -Last 1).KeyProtectorId
$vol.KeyProtector | Where-Object { $_.KeyProtectorId -ne $keep } |
ForEach-Object { Remove-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $_.KeyProtectorId }

# Force recovery on next boot, then annihilate the .bek
manage-bde -forcerecovery C: | Tee-Object -FilePath $log_commands -Append

Remove-Item "$(Split-Path $bekPath)\*.bek" -Force

# overwrite free space where the .bek lived (optional)
# cipher /w:C:\Windows\Temp | Tee-Object -FilePath $log_commands -Append

# TPM Clear may not work, but also doesn't matter that much:
Initialize-Tpm -AllowClear -AllowPhysicalPresence

shutdown /r /t 0
