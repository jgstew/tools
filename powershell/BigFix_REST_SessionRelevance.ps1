# based upon https://github.com/jgstew/tools/blob/master/powershell/BigFix_REST_SessionRelevance_Simple.ps1

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

$SessionRelevanceQuery = 'number of bes computers'

$server = 'bigfix' # BigFix Root Server address
$port = '52311' # BigFix Root Server port

$urlbase = "https://${server}:${port}/api/"

$credential = Get-Credential

# https://www.powershelladmin.com/wiki/Powershell_prompt_for_password_convert_securestring_to_plain_text#Getting_the_password_out_of_a_Get-Credential_object
$EncodedPassword = [System.Convert]::ToBase64String( [System.Text.Encoding]::UTF8.GetBytes($credential.UserName + ':' + $credential.GetNetworkCredential().Password) )
$headers = @{"Authorization"="Basic $($EncodedPassword)"}

# https://stackoverflow.com/questions/23548386/how-do-i-replace-spaces-with-20-in-powershell
# https://developer.bigfix.com/rest-api/api/query.html
$url= $urlbase + 'query?relevance=' + [uri]::EscapeDataString($SessionRelevanceQuery)

[xml]$response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers


#Write-Host $response.InnerXml #Get RAW XML

# https://stackoverflow.com/a/6143482/861745
# Get Answer(s):
Write-Host $response.BESAPI.Query.InnerXml
