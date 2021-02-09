
# GOAL: To rename the local computer and join it to a domain in 1 step with only 1 required reboot.

# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/add-computer?view=powershell-5.1
# https://stackoverflow.com/questions/6217799/rename-computer-and-join-to-domain-in-one-step-with-powershell

# get the domain credential 
$cred = get-credential
#$oldName = hostname
$newName = Read-Host -Prompt "Enter New Computer Name"

Rename-Computer -Force -PassThru -NewName $newName

Add-Computer -Force -PassThru -DomainName DEMO.MYLAB.Local -Credential $cred -ComputerName "localhost" -newname $newName

# Rename-Computer -Force -PassThru -DomainCredential Get-Credential -NewName $newName

# Requires Restart:
# Restart-Computer
