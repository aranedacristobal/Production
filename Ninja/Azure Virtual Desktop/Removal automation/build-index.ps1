#Connect-AzAccount 

# Bygg ett index för att mata andra skript för devpool som går vidare till andra skript för HostPoolen, det är härifrån vi tar fram data
# Utöver logiken i att hitta de lägstnumrerade maskiner gör vi även en check att kolla om maskinerna är "available" i hostpoolen om nej avbryt om
# Om det är "available" så skickar vi vidare till nästa skript
#----------------------------------------------------------------------------------------------------------------------------------------------->
#----------------------------------------------------------------------------------------------------------------------------------------------->
#----------------------------------------------------------------------------------------------------------------------------------------------->
Start-Transcript -Path "$Env:temp\build-index.log"

# Variabler 

$hostPoolresourceGroup  = ""
$hostPoolName           = ""

# Array
$sessionHostIndex = @()

# Börja
$hostPool = Get-AzWvdHostPool -ResourceGroupName $hostPoolresourceGroup -Name $hostPoolName -ErrorAction SilentlyContinue

# Logiken för att hämta sessions hostarna
if ($hostPool) {
    $sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $hostPoolresourceGroup -HostPoolName $hostPoolName
    if ($sessionHosts) {
        # Loopa
        foreach ($sessionHost in $sessionHosts) {
            $sessionHostIndex += [PSCustomObject]@{
                HostName = $sessionHost.Name
                Status   = $sessionHost.Status
            }
        }

        # Skapa en tabell
        $numericHostMap = @{}

        foreach ($sessionHost in $sessionHostIndex) {
            if ($sessionHost.HostName -match 'test-(\d+)-(\d+)') {
                $numericValue = [int]$matches[1]  # Extrahera siffror
                $suffix = [int]$matches[2]         # Extrahera suffixen med siffor

                # Skapa en unik nyckel för det numeriska värdet
                $key = "test-$numericValue"

                if (-not $numericHostMap.ContainsKey($key)) {
                    $numericHostMap[$key] = @()
                }

                $numericHostMap[$key] += [PSCustomObject]@{
                    HostName = $sessionHost.HostName
                    Status   = $sessionHost.Status
                    Suffix   = $suffix
                }
            }
        }

        # Hitta det lägsta numeriska värdet
        $lowestNumericValue = $numericHostMap.Keys | ForEach-Object {
            [int]($_ -replace 'test-', '')
        } | Sort-Object | Select-Object -First 1

        # Hitta alla hostar med det lägsta numeriska värdet
        $lowestSessionHosts = @()
        $lowestKey = "test-$lowestNumericValue"

        if ($numericHostMap.ContainsKey($lowestKey)) {
            $lowestSessionHosts = $numericHostMap[$lowestKey]
        }

        # Spotta ut alla sessionhostar
        Write-Host "Index of Current Session Hosts in Host Pool '$hostPoolName':"
        $sessionHostIndex | Format-Table -AutoSize

        # Skriv ut de lägsta sessionhostarna
        if ($lowestSessionHosts.Count -gt 0) {
            Write-Host "Lowest Session Hosts in Host Pool '$hostPoolName':"
            $lowestSessionHosts | ForEach-Object { Write-Host "$($_.HostName) $($_.Status)" }
        } else {
            Write-Host "No session hosts found with the lowest numeric value."
        }
    } else {
        Write-Host "No session hosts found in the host pool '$hostPoolName'."
    }
} else {
    Write-Host "Host pool '$hostPoolName' does not exist in resource group '$resourceGroupName'."
}

#----------------------------------------------------------------------------------------------------------------------------------------------->
#----------------------------------------------------------------------------------------------------------------------------------------------->
#----------------------------------------------------------------------------------------------------------------------------------------------->
# Villkor att uppfyllas inför borttagning

if ($lowestSessionHosts | Where-Object { $_.Status -ne "Shutdown" }) {
    Write-Host "Not all session hosts are in Shutdown status. Exiting the script."
    exit  
} else {
    Write-Host "All session hosts are in Shutdown status. Proceeding to the next script."
    $lowestSessionHosts | ForEach-Object {
        Write-Host "Processing host: $($_.HostName) with status: $($_.Status)"
    }
}

# Extrahera önskad del av HostName (allt efter det sista '/' och innan det)
$extractedNames = $lowestSessionHosts | ForEach-Object {
    $_.HostName -replace '.*?/(test-\d+-\d+)\..*', '$1'
}

# Output
$extractedNames

# Array för att matcha $extractedNames mot resurser för att mata nästa skript 
$foundResources = @()

foreach ($name in $extractedNames) {
    $resources = Get-AzResource | Where-Object { $_.Name -like "*$name*" }

    # Lägg till resurserna i arrayen
    $foundResources += $resources
}
$foundResources | Format-Table Name, ResourceType, ResourceGroupName


#. "C:\Users\CristobalAraneda\Git\Azure DevOps\Azure\Kunder\Brunswick\dev\azure\Removingobjects-dev-pool\Actions\remove-azure-vms.ps1"
#. "C:\Users\CristobalAraneda\Git\Azure DevOps\Azure\Kunder\Brunswick\dev\azure\Removingobjects-dev-pool\Actions\remove-azure-register.ps1"
#. "C:\Users\CristobalAraneda\Git\Azure DevOps\Azure\Kunder\Brunswick\dev\azure\Removingobjects-dev-pool\Actions\remove-active-directory-computers.ps1"
#. "C:\Users\CristobalAraneda\Git\Azure DevOps\Azure\Kunder\Brunswick\dev\azure\Removingobjects-dev-pool\Actions\remove-hostsessions.ps1"

Stop-Transcript
