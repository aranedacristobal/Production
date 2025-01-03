Write-Host "Hämtar TOKEN och triggar skript"
# Fetch TOKEN
$urlToken = "YOUR OATH TOKEN URL"
$bodyToken = @{
    grant_type    = "client_credentials"
    client_id     = $retrievedSecrets['clientIdSecretName']  
    client_secret = $retrievedSecrets['secretPw']    
    scope         = "monitoring"
}

# Build the request
$responseToken = Invoke-RestMethod -Uri $urlToken -Method Post -ContentType "application/x-www-form-urlencoded" -Body $bodyToken

$accessToken = $responseToken.access_token 

& 'C:\Ninja\Ninja-automation\List\Organisations\Ninja-Get-organisations.ps1'