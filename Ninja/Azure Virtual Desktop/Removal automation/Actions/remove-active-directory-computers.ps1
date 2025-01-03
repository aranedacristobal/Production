#Måste jobba fram en lösning som funktionerar går inte att utan att ta bort "child object"

Start-Transcript -Path "$Env:temp\remove-active-directory-computers.log"

# Define the pattern for the computer names to remove
$pattern = "YOUR-INDEX"

# Get the list of computers matching the pattern
$computersToRemove = Get-ADComputer -Filter { Name -like $pattern } | Select-Object Name, DistinguishedName

# Check if any computers were found
if ($computersToRemove.Count -eq 0) {
    Write-Host "No computers found matching the pattern '$pattern'."
} else {
    # Loop through each computer and remove it
    foreach ($computer in $computersToRemove) {
        try {
            # Check for child objects
            $childObjects = Get-ADObject -Filter * -SearchBase $computer.DistinguishedName
            if ($childObjects.Count -gt 0) {
                # Remove child objects first
                foreach ($child in $childObjects) {
                    try {
                        Remove-ADObject -Identity $child.DistinguishedName -Confirm:$false
                        Write-Host "Removed child object: $($child.Name)"
                    } catch {
                        Write-Host "Failed to remove child object: $($child.Name). Error: $_"
                    }
                }
            }

            # Now remove the computer object
            Remove-ADComputer -Identity $computer.DistinguishedName -Confirm:$false
            Write-Host "Removed computer: $($computer.Name)"
        } catch {
            Write-Host "Failed to remove computer: $($computer.Name). Error: $_"
        }
    }
}

Stop-Transcript
