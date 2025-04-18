try {
    "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

#Import-Module Az.DesktopVirtualization
#Install-Module Az.DesktopVirtualization

# Get the current date
$currentDate = Get-Date

# Calculate the first day of the current month
$firstDayOfMonth = New-Object DateTime($currentDate.Year, $currentDate.Month, 1)

# Calculate the number of Tuesdays in the current month
$tuesdayCount = 0
1..$currentDate.Day | ForEach-Object {
    $testDate = $firstDayOfMonth.AddDays($_)
    if ($testDate.DayOfWeek -eq 'Tuesday') {
        $tuesdayCount++
    }
}

# Check if it's the third Tuesday
if ($tuesdayCount -eq 3 -and $currentDate.DayOfWeek -eq 'Tuesday') {
    # Update scaling plan 
            Update-AzWvdScalingPlan `
            -ResourceGroupName 'YOUR-RESOURCEGROUP-NAME' `
            -Name 'SCALING-SETNAME'`
            -HostPoolReference @(
                    @{
                        'HostPoolArmPath' = 'hostpool-id';
                        'ScalingPlanEnabled' = $false;
                    },
                    @{
                        'HostPoolArmPath' = 'hostpool-id';
                        'ScalingPlanEnabled' = $false;
                    } )
} else {
    # Call the Set-AVDHostPoolAutoScaling function
            Update-AzWvdScalingPlan `
            -ResourceGroupName 'YOUR-RESOURCEGROUP-NAME' `
            -Name 'SCALING-SETNAME'`
            -HostPoolReference @(
                    @{
                        'HostPoolArmPath' = '/hostpool-id';
                        'ScalingPlanEnabled' = $true;
                    },
                    @{
                        'HostPoolArmPath' = 'hostpool-id';
                        'ScalingPlanEnabled' = $true;
                    } )
}
