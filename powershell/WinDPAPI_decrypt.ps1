# NOTE: this only works to decrypt a string when run from the system it was encrypted on
#       if the string was encrypted in user scope, it must be run as that user

# Related: https://github.com/jgstew/tools/blob/master/Python/WinDPAPI_decrypt.py

# Load the necessary .NET assembly. This fixes the "Unable to find type" error.
Add-Type -AssemblyName System.Security

# put string to decrypt here:
$base64String = ""

try {
  # Convert the Base64 string to a byte array
  $encryptedBytes = [System.Convert]::FromBase64String($base64String)

  # Use the ProtectedData class to unprotect (decrypt) the data.
  # The scope is now changed to ::LocalMachine
  $unprotectedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
    $encryptedBytes,
    $null, # Optional Entropy
    # [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    [System.Security.Cryptography.DataProtectionScope]::LocalMachine
  )

  # Convert the decrypted byte array back to a readable string
  $decryptedString = [System.Text.Encoding]::UTF8.GetString($unprotectedBytes)

  Write-Host "Decryption Successful!" -ForegroundColor Green
  Write-Host "Decrypted String: $decryptedString"

}
catch {
  Write-Host "Decryption Failed." -ForegroundColor Red
  Write-Host "Error: $($_.Exception.Message)"
  Write-Host "This could mean:"
  Write-Host "1. You are not running with sufficient permissions (e.g., as Administrator)."
  Write-Host "2. The data was not encrypted on this machine."
  Write-Host "3. The data was originally encrypted with 'CurrentUser' scope, not 'LocalMachine'."
}
