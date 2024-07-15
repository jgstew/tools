Add-Type -AssemblyName System.Device
$watcher = New-Object System.Device.Location.GeoCoordinateWatcher(0)

# Define a script block to handle position changed event
$handler = {
    param($sender, $e)
    if ($sender.Permission -eq 'Denied') {
        {
            Write-Error 'Access Denied (most likely location services is not turned on)'
        }
        $sender.Stop()
    }
    Write-Output $e.Position.Location
    Write-Output "Latitude: $($e.Position.Location.Latitude), Longitude: $($e.Position.Location.Longitude)"
    # Uncomment the line below if you want to stop watching after the first location update
    # $sender.Stop()
}

# Start watching for position changes
$watcher.Start()

Start-Sleep -Seconds 3

# Register event handler
Register-ObjectEvent -InputObject $watcher -EventName PositionChanged -Action $handler

# get initial location:
Write-Output $watcher.Position.Location

# Wait for a few seconds to allow location updates
Start-Sleep -Seconds 60

# Stop watching (optional)
$watcher.Stop()
