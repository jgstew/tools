# based upon script by Jeff Schafer

# Invoke:
# powershell -ExecutionPolicy Bypass .\BigFix_REST_LoginExample.ps1

add-type @"
  using System.Net;
  using System.Security.Cryptography.X509Certificates;
  public class TrustAllCertsPolicy : ICertificatePolicy {
      public bool CheckValidationResult(
          ServicePoint srvPoint, X509Certificate certificate,
          WebRequest request, int certificateProblem) {
          return true;
      }
  }
"@
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$server = 'bigfix' # BigFix Root Server address
$port = '52311' # BigFix Root Server port
$urlbase = "https://${server}:${port}/api/login"

$credential = Get-Credential

$EncodedPassword = [System.Convert]::ToBase64String( [System.Text.Encoding]::UTF8.GetBytes($credential.UserName + ':' + $credential.GetNetworkCredential().Password) )
$headers = @{"Authorization"="Basic $($EncodedPassword)"}

$url= $urlbase
$response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers

Write-Host $response
