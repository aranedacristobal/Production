Write-Host "Fetching TOKEN and triggering script"
# Hämta TOKEN
$urlToken = "YOUR OATH TOKEN"
$bodyToken = @{
    grant_type    = "client_credentials"
    client_id     = $retrievedSecrets['clientIdSecretName']  
    client_secret = $retrievedSecrets['secretPw']    
    scope         = "monitoring"
}

# Build http-request
$responseToken = Invoke-RestMethod -Uri $urlToken -Method Post -ContentType "application/x-www-form-urlencoded" -Body $bodyToken

$accessToken = $responseToken.access_token 


& 'Ninja\Ninja-automation\List\Locations\Ninja-Get-locations.ps1'