#PARAMETRAR 

param (
    [string[]]$ResourceGroupName, # Namnet på resursgruppen(er)
    [string[]]$VmNames,             # Namnen på de VM:ar som ska tas bort
    [string[]]$AzureADObjectIds,    # ID:n för de Azure AD-objekt som ska tas bort
    [string]$HostPoolName,          # Namnet på hostpoolen
    [string[]]$ADComputerNames      # Namnen på datorobjekten i Active Directory som ska tas bort
)

#Importera nödvändiga moduler
Import-Module Az.Compute
Import-Module Az.Resources
Import-Module AzureAD # eller använd Microsoft.Graph om så önskas
Import-Module Az.DesktopVirtualization # För att hantera AVD host pools
Import-Module ActiveDirectory # För att hantera Active Directory-objekt

#-------------------------------------------------------------------------------------------------------------------------------------------------#
#AZURE VMs
#-------------------------------------------------------------------------------------------------------------------------------------------------#

# Ta bort virtuella maskiner
foreach ($vmName in $VmNames) {
    foreach ($rg in $ResourceGroupName) {
        try {
            # Hämta den virtuella maskinen
            $vm = Get-AzVM -ResourceGroupName $rg -Name $vmName -ErrorAction Stop
            
            # Stoppa VM:en (om den körs)
            Stop-AzVM -ResourceGroupName $rg -Name $vmName -Force -ErrorAction Stop
            
            # Ta bort VM:en
            Remove-AzVM -ResourceGroupName $rg -Name $vmName -Force -ErrorAction Stop
            
            Write-Output "Tog bort VM: $vmName i resursgruppen: $rg"
        } catch {
            Write-Error "Fel vid borttagning av VM $vmName i resursgruppen $rg: $_"
        }
    }
}

#-------------------------------------------------------------------------------------------------------------------------------------------------#
#Entra ID
#-------------------------------------------------------------------------------------------------------------------------------------------------#

# Steg 2: Ta bort Azure AD-objekt
foreach ($objectId in $AzureADObjectIds) {
    try {
        # Ta bort Azure AD-objektet
        Remove-AzureADObject -ObjectId $objectId -ErrorAction Stop
        
        Write-Output "Tog bort Azure AD-objekt med ID: $objectId"
    } catch {
        Write-Error "Fel vid borttagning av Azure AD-objekt med ID $objectId: $_"
    }
}

#-------------------------------------------------------------------------------------------------------------------------------------------------#
#Hostpool borttagning
#-------------------------------------------------------------------------------------------------------------------------------------------------#
foreach ($vmName in $VmNames) {
    try {
        # Ta bort VM:en från hostpoolen
        Remove-AzWvdSessionHost -ResourceGroupName $ResourceGroupName[0] -HostPoolName $HostPoolName -Name $vmName -Force -ErrorAction Stop
        
        Write-Output "Tog bort VM: $vmName från hostpoolen: $HostPoolName"
    } catch {
        Write-Error "Fel vid borttagning av VM $vmName från hostpoolen $HostPoolName: $_"
    }
}

#-------------------------------------------------------------------------------------------------------------------------------------------------#
#Active Directory borttagning
#-------------------------------------------------------------------------------------------------------------------------------------------------#
foreach ($computerName in $ADComputerNames) {
    try {
        # Ta bort datorobjektet från Active Directory
        Remove-ADComputer -Identity $computerName -Confirm:$false -ErrorAction Stop
        
        Write-Output "Tog bort datorobjekt: $computerName från Active Directory"
    } catch {
        Write-Error "Fel vid borttagning av datorobjekt $computerName från Active Directory: $_"
    }
}