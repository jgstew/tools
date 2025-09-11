# based upon https://github.com/jgstew/tools/blob/master/powershell/BigFix_REST_LoginExample.ps1

# Invoke:
# powershell -ExecutionPolicy Bypass .\BigFix_REST_SessionRelevance.ps1

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

# https://developer.bigfix.com/rest-api/api/query.html
$urlbase = "https://${server}:${port}/api/query?relevance=number+of+bes+computers"

$credential = Get-Credential

$EncodedPassword = [System.Convert]::ToBase64String( [System.Text.Encoding]::UTF8.GetBytes($credential.UserName + ':' + $credential.GetNetworkCredential().Password) )
$headers = @{"Authorization"="Basic $($EncodedPassword)"}

$url= $urlbase
[xml]$response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers


#Write-Host $response.InnerXml #Get RAW XML

# Get Answer(s):
Write-Host $response.BESAPI.Query.Result.InnerXml
