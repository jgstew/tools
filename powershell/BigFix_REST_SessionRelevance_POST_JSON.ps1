# based upon https://github.com/jgstew/tools/blob/master/powershell/BigFix_REST_SessionRelevance_Simple.ps1

# Invoke:
# powershell -ExecutionPolicy Bypass .\BigFix_REST_SessionRelevance.ps1

$SessionRelevanceQuery = 'names whose(it contains "-") of bes computers'

$server = 'bigfix' # BigFix Root Server address
$port = '52311' # BigFix Root Server port

$urlbase = "https://${server}:${port}/api/"

$credential = Get-Credential

# https://www.powershelladmin.com/wiki/Powershell_prompt_for_password_convert_securestring_to_plain_text#Getting_the_password_out_of_a_Get-Credential_object
$EncodedPassword = [System.Convert]::ToBase64String( [System.Text.Encoding]::UTF8.GetBytes($credential.UserName + ':' + $credential.GetNetworkCredential().Password) )
$headers = @{"Authorization"="Basic $($EncodedPassword)"}

# https://stackoverflow.com/questions/23548386/how-do-i-replace-spaces-with-20-in-powershell
# https://developer.bigfix.com/rest-api/api/query.html
$url= $urlbase + 'query'

# https://stackoverflow.com/questions/17325293/invoke-webrequest-post-with-parameters
$PostBody= @{relevance= [uri]::EscapeDataString($SessionRelevanceQuery)}
$PostBody = @{
    'output'= 'json'
    'relevance' = [uri]::EscapeDataString($SessionRelevanceQuery)
} | ConvertTo-Json -Depth 10

# Allow invalid SSL certificates
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

$response = Invoke-RestMethod -Uri $url -Method POST -Body $PostBody -Headers $headers

# Get Answer(s): 
Write-Host $response
