<#
.SYNOPSIS
    Edit BigFix client MSI to incorporate custom client settings.

.DESCRIPTION
    This script modifies a BigFix MSI installer by adding registry entries
    for custom client settings read from a configuration file.
    There is a python version of this script here: Python\bigfix_client_msi_clientsettings.py
    This file was generated using Claude Sonnet 4.5 and asking it to convert the python version to powershell.
    This powershell script was then tested successfully on Windows 11.

.PARAMETER InputMsi
    Path to the input MSI file to modify.

.PARAMETER ClientSettings
    Path to the client settings configuration file (default: clientsettings.cfg).

.EXAMPLE
    .\bigfix_client_msi_clientsettings.ps1 -InputMsi "C:\Path\To\BigFixAgent.msi" -ClientSettings "clientsettings.cfg"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$InputMsi,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientSettings = "clientsettings.cfg"
)

function Update-MsiProperty {
    <#
    .SYNOPSIS
        Updates a property in an MSI database.
    #>
    param(
        [string]$MsiPath,
        [string]$PropertyName,
        [string]$NewValue
    )
    
    try {
        # Initialize the Windows Installer Object
        $installer = New-Object -ComObject WindowsInstaller.Installer
        
        # Open the database (2 = msiOpenDatabaseModeTransact)
        $db = $installer.OpenDatabase($MsiPath, 2)
        
        # Execute a SQL Update query
        $query = "UPDATE ``Property`` SET ``Value`` = '$NewValue' WHERE ``Property`` = '$PropertyName'"
        $view = $db.OpenView($query)
        $view.Execute()
        
        # Commit changes
        $db.Commit()
        Write-Host "Updated $PropertyName to $NewValue"
        
        # Clean up
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($view) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($db) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($installer) | Out-Null
    }
    catch {
        Write-Error "Failed to update MSI property: $_"
        throw
    }
}

function Add-BigFixClientSettingToMsi {
    <#
    .SYNOPSIS
        Inserts BigFix configuration registry keys into an MSI file.
    #>
    param(
        [string]$MsiPath,
        [string]$SettingName,
        [string]$SettingValue,
        [string]$Component = "BESClient.exe"
    )
    
    try {
        # Initialize the Windows Installer Object
        $installer = New-Object -ComObject WindowsInstaller.Installer
        
        # Open the database (2 = msiOpenDatabaseModeTransact)
        $db = $installer.OpenDatabase($MsiPath, 2)
        
        # Define registry parameters
        $registryId = $SettingName  # Unique ID for the registry entry
        $root = 2  # HKEY_LOCAL_MACHINE
        $key = "SOFTWARE\BigFix\EnterpriseClient\Settings\Client\$SettingName"
        $value = $SettingValue
        
        # Prepare the SQL Insert query
        $query = "INSERT INTO ``Registry`` (``Registry``, ``Root``, ``Key``, ``Name``, ``Value``, ``Component_``) " +
                 "VALUES ('$registryId', $root, '$key', 'value', '$value', '$Component')"
        
        $view = $db.OpenView($query)
        $view.Execute()
        
        # Commit changes
        $db.Commit()
        Write-Host "Inserted registry setting $SettingName with value $SettingValue"
        
        # Clean up
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($view) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($db) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($installer) | Out-Null
    }
    catch {
        Write-Error "Failed to add registry setting to MSI: $_"
        throw
    }
}

function Get-ClientSettingsFromFile {
    <#
    .SYNOPSIS
        Reads client settings from a configuration file.
    #>
    param(
        [string]$SettingsPath
    )
    
    $settings = @{}
    
    if (-not (Test-Path $SettingsPath)) {
        Write-Error "Settings file not found: $SettingsPath"
        return $null
    }
    
    Get-Content $SettingsPath | ForEach-Object {
        $line = $_.Trim()
        # Skip empty lines and comments
        if ($line -and -not $line.StartsWith("#")) {
            $parts = $line -split "=", 2
            if ($parts.Count -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim()
                $settings[$key] = $value
            }
        }
    }
    
    return $settings
}

# Main execution
Write-Host "BigFix Client MSI ClientSettings Editor (PowerShell)"
Write-Host "=================================================="

# Validate input MSI file
if (-not (Test-Path $InputMsi)) {
    Write-Error "Input MSI file '$InputMsi' does not exist. Provide correct path using -InputMsi parameter."
    exit 1
}

# Validate client settings file
if (-not (Test-Path $ClientSettings)) {
    Write-Error "Client settings file '$ClientSettings' does not exist. Provide correct path using -ClientSettings parameter."
    exit 1
}

# Generate output MSI path
$inputMsiItem = Get-Item $InputMsi
$outputMsi = Join-Path $inputMsiItem.DirectoryName ($inputMsiItem.BaseName + "_modified" + $inputMsiItem.Extension)

# Delete output MSI if it already exists
if (Test-Path $outputMsi) {
    Write-Host "Removing existing output file: $outputMsi"
    Remove-Item $outputMsi -Force
}

# Read client settings
Write-Host "`nReading client settings from: $ClientSettings"
$settings = Get-ClientSettingsFromFile -SettingsPath $ClientSettings

if ($null -eq $settings -or $settings.Count -eq 0) {
    Write-Error "No valid settings found in the configuration file."
    exit 1
}

Write-Host "Client settings to apply:"
$settings.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key) = $($_.Value)"
}

# Copy input MSI to output MSI
Write-Host "`nCopying MSI file..."
Copy-Item -Path $InputMsi -Destination $outputMsi -Force

# Edit the MSI registry entries based on settings
Write-Host "`nApplying settings to MSI..."
foreach ($setting in $settings.GetEnumerator()) {
    Add-BigFixClientSettingToMsi -MsiPath $outputMsi -SettingName $setting.Key -SettingValue $setting.Value
}

Write-Host "`nModified MSI saved as '$outputMsi'"
Write-Host "Done!"

# Clean up any remaining COM objects
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()