# https://gist.github.com/nijave/d657fb4cdb518286942f6c2dd933b472

[void][Windows.Networking.Connectivity.NetworkInformation, Windows, ContentType = WindowsRuntime]
$cost = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile().GetConnectionCost()

# $cost.ApproachingDataLimit -or $cost.OverDataLimit -or $cost.Roaming -or $cost.BackgroundDataUsageRestricted

Write-Host "Cost Type: $($cost.NetworkCostType)"

Write-Host "Metered Connection: $($cost.ApproachingDataLimit -or $cost.OverDataLimit -or $cost.Roaming -or $cost.BackgroundDataUsageRestricted)"
