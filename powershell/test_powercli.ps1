# https://www.iannoble.co.uk/use-powershell-core-visual-studio-code/
Write-Host "PowerShell Version:" $PSVersionTable.PSVersion
# https://communities.vmware.com/thread/547173
Import-Module -Name VMware.VimAutomation.Core
Get-Module

# https://www.vmware.com/support/developer/windowstoolkit/wintk40u1/html/Connect-VIServer.html
Connect-VIServer -Server "_SERVER_"

#Get-VMHostNetwork -VMHost _SERVER_
#Get-VirtualPortGroup
#Get-VMHost
# https://www.vmware.com/support/developer/PowerCLI/PowerCLI651/html/DatastoreCluster.html
#Get-DatastoreCluster

# https://www.vmware.com/support/developer/PowerCLI/PowerCLI651/html/Get-ResourcePool.html
Get-ResourcePool

# https://www.vmware.com/support/developer/PowerCLI/PowerCLI651/html/Import-VApp.html

## This worked:
#Import-VApp -Source "_PATH_\Win7.ova" -Name "PowerCLItest Win7" -Datastore _NAME_DS05 -VMHost esxi120._FQDN_

# Enable Paste for all VMs:
Get-VM | New-AdvancedSetting -name "isolation.tools.paste.disable" -Value $false -Confirm:$false
