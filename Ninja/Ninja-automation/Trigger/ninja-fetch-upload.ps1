Start-Transcript -Path "$env:TEMP\ninja-fetch-upload.log"

"<---------------------------------------------------------------------------------------------------------------------------------------------->"
"<---------------------------------------------------------------------------------------------------------------------------------------------->"

# Connect with a managed identity to access your keyvault, you could have the token bearer you API Secret in clear text but I rather not
Connect-AzAccount -Identity

# Variabler
$keyVaultName = "YOUR-KEYVAULT-NAME"  
$secrets = @{
    clientIdSecretName = "YOUR-SECRET-NAME"  
    secretPw           = "YOUR-SECRET" 
}

# Build hashtable
$retrievedSecrets = @{}

# Get secrets
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

# Path 
$csvPath = "Ninja\Ninja-automation\List\output2.csv"  

# Read CSV
$data = Import-Csv -Path $csvPath -Delimiter ','  

$urlToken = "YOUR URL TOKEN"
$bodyToken = @{
    grant_type    = "client_credentials"
    client_id     = $retrievedSecrets['clientIdSecretName']  
    client_secret = $retrievedSecrets['secretPw']            
    scope         = "management"
}


# Build your request based
$responseToken = Invoke-RestMethod -Uri $urlToken -Method Post -ContentType "application/x-www-form-urlencoded" -Body $bodyToken
$accessToken = $responseToken.access_token 

# Build array
$downloadUrls = @()

# Loop
foreach ($record in $data) {
    $organizationId = $record.organizationid
    $locationId = $record.locationid

    # Log
    Write-Host "Processing record for Organization ID: $organizationId, Location ID: $locationId"

    # Variables
    $url = "YOUR URL FOR FETCHING INSTALLERS"

    # Define head
    $headers = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $accessToken"
        "Content-Type"  = "application/json"
    }

    # Define body
    $body = @{
        organizationId = $organizationId
        locationId     = $locationId
        installerType  = "WINDOWS_MSI"
        content        = @{
            nodeRoleId = "auto"
        }
    } | ConvertTo-Json

    # Build a request 
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body

        # Control
        if ($response -and $response.url) {
            # Build an URL
            $ninjaInstaller = $response.url 

            # Log
            Write-Host "Installer generated successfully. Download URL: $ninjaInstaller"

            # Store
            $downloadUrls += $ninjaInstaller
        } else {
            Write-Host "No URL returned for Organization ID: $organizationId. Response: $response"
        }
    } catch {
        Write-Host "Error generating installer for Organization ID: $organizationId. Error: $_"
    }
}

# Dump
$downloadUrls | Out-File -FilePath "Ninja\Ninja-installers\downloadUrls.txt"  

"<---------------------------------------------------------------------------------------------------------------------------------------------->"
"<---------------------------------------------------------------------------------------------------------------------------------------------->"

# Variables
$urlsFilePath = "Ninja\Ninja-installers\downloadUrls.txt"  
$downloadPath = "Ninja\Ninja-installers"  

# Read
$downloadUrls = Get-Content -Path $urlsFilePath

# Create
$webClient = New-Object System.Net.WebClient

# Hash
$processedUrls = @{}

# Loop
foreach ($url in $downloadUrls) {
    if ($processedUrls.ContainsKey($url)) {
        Write-Host "Duplicate URL found: $url. Stopping the script."
        break  # Break if they are the same
    }

    # Mark as handled
    $processedUrls[$url] = $true

    # Extract
    $fileName = [System.IO.Path]::GetFileName($url)  

    # Merge
    $fullPath = Join-Path -Path $downloadPath -ChildPath $fileName

    # Download
    try {
        $webClient.DownloadFile($url, $fullPath)
        Write-Host "Downloaded: $fullPath"
    } catch {
        Write-Host "Error downloading $url. Error: $_"
    }
}

# Dump
$webClient.Dispose()

"<---------------------------------------------------------------------------------------------------------------------------------------------->"
"<---------------------------------------------------------------------------------------------------------------------------------------------->"

# Variables
$keyVaultName               = "YOUR KEYVAULT NAME"  
$Secrets = @{
            secretappidpw   = "YOUR APPLICATION PASSWORD"  
            secretappid     = "YOUR APPLICATION ID"
            secrettenantid  = "YOUR TENANT ID"
}

# Array
$retrievedSecrets = @{}

# Get secrets
try {
    foreach ($key in $Secrets.Keys) {
        $secret = az keyvault secret show --vault-name $keyVaultName --name $Secrets[$key] | ConvertFrom-Json
        
        
        # Confirm data
        if ($null -eq $secret) {
            Write-Host "Secret '$key' not found."
        } else {
            # Store data
            $retrievedSecrets[$key] = $secret.value
        }
    }
} catch {
    Write-Host "Error retrieving secret: $_"
}

# Variables
$tenantId            = $retrievedSecrets['secrettenantid']  
$appId               = $retrievedSecrets['secretappid']         
$password            = $retrievedSecrets['secretappidpw']    

# Variables
$resourceGroupName   = "YOUR RESOURCE GROUP NAME"
$storageAccountName  = "STORAGE ACCOUNT NAME"
$containerName       = "CONTAINER NAME"  
$expiryTime          = (Get-Date).AddMinutes(10)

# Context
$context = New-AzStorageContext -StorageAccountName $storageAccountName

# Confirm
$container = Get-AzStorageContainer -Name $containerName -Context $context
if ($null -eq $container) {
    Write-Host "Container '$containerName' does not exist in storage account '$storageAccountName'."
    exit
}

"<---------------------------------------------------------------------------------------------------------------------------------------------->"
"<---------------------------------------------------------------------------------------------------------------------------------------------->"

# Create SAS-token
$sasToken = New-AzStorageContainerSASToken -Name $containerName -Context $context -ExpiryTime $expiryTime -Permission rwdl

# Build URL
$storageAccountUrl = "https://$storageAccountName.blob.core.windows.net/CONTAINERNAME?$sasToken"

# Upload
azcopy.exe sync "Ninja\Ninja-installers" "$storageAccountUrl" --recursive=true

Stop-Transcript

