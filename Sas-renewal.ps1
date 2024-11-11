# Variabler
$resourceGroup = "cloud-shell-storage-westeurope"
$storageAccount = "labcristobal"
$container = "vdot"

# Utfallsdatum
$expiryDate = (Get-Date).AddHours(24) # Example: valid for 24 hours

$sasToken = (az storage container generate-sas `
    --account-name $storageAccount `
    --name $container `
    --permissions rwdl `
    --expiry $expiryDateFormatted `
    --auth-mode login `
    --as-user `
    --output tsv)

# Kontrollera om SAS-token genererades framgångsrikt
if (-not $sasToken) {
    Write-Error "Failed to generate SAS token."
    exit 1
}

# Bygg ihop URL
$sasUrl = "https://$storageAccount.blob.core.windows.net/$container?$sasToken"

# Spara SAS URL för användning
Write-Output "SAS URL: $sasUrl"