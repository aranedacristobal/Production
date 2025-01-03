Write-Host "Hämtar TOKEN och triggar skript"
# Hämta TOKEN
$urlToken = "YOUR OATH TOKEN"
$bodyToken = @{
    grant_type    = "client_credentials"
    client_id     = $retrievedSecrets['clientIdSecretName']  
    client_secret = $retrievedSecrets['secretPw']    
    scope         = "monitoring"
}

# Bygg en HTTP-begäran 
$responseToken = Invoke-RestMethod -Uri $urlToken -Method Post -ContentType "application/x-www-form-urlencoded" -Body $bodyToken

# Spotta till nästa skript för användning
$accessToken = $responseToken.access_token 


& 'Ninja\Ninja-automation\List\Locations\Ninja-Get-locations.ps1'