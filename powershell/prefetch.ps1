# Usage Examples:
# prefetch statement:
# powershell -ExecutionPolicy Bypass .\prefetch.ps1 "'prefetch string.txt sha1:? size:? url sha256:?'"
# prefetch block item:
# powershell -ExecutionPolicy Bypass .\prefetch.ps1 "'add prefetch item name=string.txt sha1=? size=? url=? sha256=?'"
$prefetch = $args[0]

if (!$prefetch) { 
    $prefetch = "prefetch unzip.exe sha1:84debf12767785cd9b43811022407de7413beb6f size:204800 http://software.bigfix.com/download/redist/unzip-6.0.exe sha256:2122557d350fd1c59fb0ef32125330bde673e9331eb9371b454c2ad2d82091ac"
}

Write-Host $prefetch

$prefetch_name = ( select-string "(?:name=|prefetch )([a-zA-Z0-9\.]+)(?: |$)" -inputobject $prefetch ).Matches.groups[1].value

$prefetch_sha256 = ( select-string "(?:sha256:|sha256=)([a-zA-Z0-9]+)(?: |$)" -inputobject $prefetch ).Matches.groups[1].value

$prefetch_url = ( select-string "(?: |url=)(http[-:/.a-zA-Z0-9]+)(?: |$)" -inputobject $prefetch ).Matches.groups[1].value

$prefetch_size = ( select-string "(?:size:|size=)([0-9]+)(?: |$)" -inputobject $prefetch ).Matches.groups[1].value

# Write-Host $prefetch_size

(New-Object Net.WebClient).DownloadFile($prefetch_url, $prefetch_name)

if ( (Get-Item $prefetch_name).length -eq $prefetch_size ) {
    # Write-Host "prefetch size matches file size!"

    if ( (Get-FileHash $prefetch_name).Hash -eq $prefetch_sha256 ) {
        Write-Host "prefetch succeeded, hashes match!"
    }
    else {
        Write-Host "prefetch failed! hashes do not match! deleting file."
        Remove-Item $prefetch_name
    }
}
else {
    Write-Host "prefetch failed! sizes do not match! deleting file."
    Remove-Item $prefetch_name
}