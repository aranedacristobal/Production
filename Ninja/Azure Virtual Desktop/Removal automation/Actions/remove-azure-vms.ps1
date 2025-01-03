# Borttagning av azure VM:ar får sin data från build-index.ps1
# Vi gör en check i denna skript och det är huruvida någon av resurserna innehåller en specifik tagg
#----------------------------------------------------------------------------------------------------------------------------------------------->
#----------------------------------------------------------------------------------------------------------------------------------------------->
#----------------------------------------------------------------------------------------------------------------------------------------------->
Start-Transcript -Path "$Env:temp\remove-azure-vms.log"

$foundResources = @()

foreach ($name in $extractedNames) {
    $resources = Get-AzResource | Where-Object { $_.Name -like "*$name*" }

    # Lägg till hittade resurser
    $foundResources += $resources
}

# Definiera vilka resurser vi vill matcha
$desiredResourceTypes = @(
    "Microsoft.Compute/virtualMachines",  
    "Microsoft.Compute/disks",            
    "Microsoft.Network/networkInterfaces"  
)

# Filtrera på endast de resurser som matchar de önskade typerna
$filteredResources = $foundResources | Where-Object { $desiredResourceTypes -contains $_.ResourceType }

# Säkerställ att alla resurser har taggen 'Tobedeleted=true'
$allResourcesHaveTag = $true

foreach ($resource in $filteredResources) {
    if (-not ($resource.Tags -and $resource.Tags["Tobedeleted"] -eq "true")) {
        $allResourcesHaveTag = $false
        break
    }
}
if (-not $allResourcesHaveTag) {
    Write-Host "Not all resources have the tag 'Tobedeleted=true'. Exiting script."
    exit
}

# Output resurserna som kommer tas bort
$filteredResources | Select-Object Name, ResourceType, ResourceGroupName

# Stek resurserna 
foreach ($resource in $filteredResources) {
    switch ($resource.ResourceType) {
        "Microsoft.Compute/virtualMachines" {
            Remove-AzVM -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName -Force
        }
        "Microsoft.Compute/disks" {
            Remove-AzDisk -DiskName $resource.Name -ResourceGroupName $resource.ResourceGroupName -Force
        }
        "Microsoft.Network/networkInterfaces" {
            Remove-AzNetworkInterface -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName -Force
        }
    }
}

Write-Host "Resources deleted successfully."

Stop-Transcript
