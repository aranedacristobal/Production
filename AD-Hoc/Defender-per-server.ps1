# Anslut
Connect-azaccount 

# Define variables
$subscriptionId = (get-azcontext).Subscription.Id
$resourceGroup = Read-Host
$vmName= Read-Host
$url = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/virtualMachines/$vmName/providers/Microsoft.Security/pricings/virtualMachines?api-version=2024-01-01"

## Set access token for the API request
$accessToken = (Get-AzAccessToken).Token
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

$body = @{
    location   = $location
    properties = @{
        pricingTier = "Standard"
        subPlan = "P1"
    }
} | ConvertTo-Json

## Invoke API request to enable the P1 plan on the VM
Invoke-RestMethod -Method Put -Uri $url -Body $body -Headers $headers
