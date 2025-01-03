Start-Transcript -Path "$env:TEMP\ninja-fetch-upload.log"

"<---------------------------------------------------------------------------------------------------------------------------------------------->"
"<---------------------------------------------------------------------------------------------------------------------------------------------->"

# Anslut med managerad identitet, denna behövs sättas upp och ge behörigheter innan
Connect-AzAccount -Identity

# Variabler
$keyVaultName = "YOUR-KEYVAULT-NAME"  
$secrets = @{
    clientIdSecretName = "YOUR-SECRET-NAME"  
    secretPw           = "YOUR-SECRET" 
}

# Hashtabell
$retrievedSecrets = @{}

# Hämta hemligheterna i en for-loop av ngn anledning går det inte med powershell (gick med az cli)
foreach ($key in $secrets.Keys) {
    try {
        $secret = az keyvault secret show --vault-name $keyVaultName --name $secrets[$key] | ConvertFrom-Json
        if ($null -eq $secret) {
            Write-Host "Secret '$key' not found."
        } else {
            $retrievedSecrets[$key] = $secret.value
            Write-Host "Retrieved Secret"
        }
    } catch {
        Write-Host "Error retrieving secret '$key': $_"
    }
}


"<---------------------------------------------------------------------------------------------------------------------------------------------->"
"<---------------------------------------------------------------------------------------------------------------------------------------------->"

& 'Ninja-automation/List/Ninja-build-csv.ps1'

# Sökväg 
$csvPath = "Ninja\Ninja-automation\List\output2.csv"  

# Läs in CSV
$data = Import-Csv -Path $csvPath -Delimiter ','  

$urlToken = "YOUR URL TOKEN"
$bodyToken = @{
    grant_type    = "client_credentials"
    client_id     = $retrievedSecrets['clientIdSecretName']  
    client_secret = $retrievedSecrets['secretPw']            
    scope         = "management"
}


# Bygg en HTTP-begäran för att hämta access token
$responseToken = Invoke-RestMethod -Uri $urlToken -Method Post -ContentType "application/x-www-form-urlencoded" -Body $bodyToken
$accessToken = $responseToken.access_token 

# Bygg array
$downloadUrls = @()

# Loopa
foreach ($record in $data) {
    $organizationId = $record.organizationid
    $locationId = $record.locationid

    # Logga
    Write-Host "Processing record for Organization ID: $organizationId, Location ID: $locationId"

    # Variabel
    $url = "YOUR URL FOR FETCHING INSTALLERS"

    # Definiera huvudet
    $headers = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $accessToken"
        "Content-Type"  = "application/json"
    }

    # Definiera kroppen
    $body = @{
        organizationId = $organizationId
        locationId     = $locationId
        installerType  = "WINDOWS_MSI"
        content        = @{
            nodeRoleId = "auto"
        }
    } | ConvertTo-Json

    # Bygg en HTTP-begäran 
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body

        # Kontrollera
        if ($response -and $response.url) {
            # Bygg ett URL för nedladdning
            $ninjaInstaller = $response.url 

            # Logga
            Write-Host "Installer generated successfully. Download URL: $ninjaInstaller"

            # Lagra
            $downloadUrls += $ninjaInstaller
        } else {
            Write-Host "No URL returned for Organization ID: $organizationId. Response: $response"
        }
    } catch {
        Write-Host "Error generating installer for Organization ID: $organizationId. Error: $_"
    }
}

# Dumpa i filen
$downloadUrls | Out-File -FilePath "Ninja\Ninja-installers\downloadUrls.txt"  

"<---------------------------------------------------------------------------------------------------------------------------------------------->"
"<---------------------------------------------------------------------------------------------------------------------------------------------->"

# Variabler
$urlsFilePath = "Ninja\Ninja-installers\downloadUrls.txt"  
$downloadPath = "Ninja\Ninja-installers"  

# Läs
$downloadUrls = Get-Content -Path $urlsFilePath

# Skapa klienten
$webClient = New-Object System.Net.WebClient

# Hasha
$processedUrls = @{}

# Loopa
foreach ($url in $downloadUrls) {
    if ($processedUrls.ContainsKey($url)) {
        Write-Host "Duplicate URL found: $url. Stopping the script."
        break  # Bryt om det är samma sen tidigare
    }

    # Markera det som hanterat
    $processedUrls[$url] = $true

    # Extrahera
    $fileName = [System.IO.Path]::GetFileName($url)  

    # Slå ihop
    $fullPath = Join-Path -Path $downloadPath -ChildPath $fileName

    # Ladda ner
    try {
        $webClient.DownloadFile($url, $fullPath)
        Write-Host "Downloaded: $fullPath"
    } catch {
        Write-Host "Error downloading $url. Error: $_"
    }
}

# Dumpa klienten
$webClient.Dispose()

"<---------------------------------------------------------------------------------------------------------------------------------------------->"
"<---------------------------------------------------------------------------------------------------------------------------------------------->"

# Variabler
$keyVaultName               = "YOUR KEYVAULT NAME"  
$Secrets = @{
            secretappidpw   = "YOUR APPLICATION PASSWORD"  
            secretappid     = "YOUR APPLICATION ID"
            secrettenantid  = "YOUR TENANT ID"
}

# Tabell för att lagra hemligheterna
$retrievedSecrets = @{}

# Hämta hemligheterna
try {
    foreach ($key in $Secrets.Keys) {
        $secret = az keyvault secret show --vault-name $keyVaultName --name $Secrets[$key] | ConvertFrom-Json
        
        # Säkerställ att du har fått data
        if ($null -eq $secret) {
            Write-Host "Secret '$key' not found."
        } else {
            # Lagra datat
            $retrievedSecrets[$key] = $secret.value
        }
    }
} catch {
    Write-Host "Error retrieving secret: $_"
}

# Variablerna med sina hemligheter
$tenantId            = $retrievedSecrets['secrettenantid']  
$appId               = $retrievedSecrets['secretappid']         
$password            = $retrievedSecrets['secretappidpw']    

# Variabler (dessa är till lagringskontot)
$resourceGroupName   = "YOUR RESOURCE GROUP NAME"
$storageAccountName  = "STORAGE ACCOUNT NAME"
$containerName       = "CONTAINER NAME"  
$expiryTime          = (Get-Date).AddMinutes(10)

# Kontext
$context = New-AzStorageContext -StorageAccountName $storageAccountName

# Säkerställ
$container = Get-AzStorageContainer -Name $containerName -Context $context
if ($null -eq $container) {
    Write-Host "Container '$containerName' does not exist in storage account '$storageAccountName'."
    exit
}

"<---------------------------------------------------------------------------------------------------------------------------------------------->"
"<---------------------------------------------------------------------------------------------------------------------------------------------->"

# Skapa SAS 
$sasToken = New-AzStorageContainerSASToken -Name $containerName -Context $context -ExpiryTime $expiryTime -Permission rwdl

# Bygg ihop URL
$storageAccountUrl = "https://$storageAccountName.blob.core.windows.net/CONTAINERNAME?$sasToken"

# Ladda upp
azcopy.exe sync "Ninja\Ninja-installers" "$storageAccountUrl" --recursive=true

Stop-Transcript

