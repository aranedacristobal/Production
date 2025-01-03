# Set the daily working hours
$dailyHours = 8  # Change this value if your daily working hours are different
$desiredPercentage = 82  # Desired percentage of total hours

# Function to calculate working days in a month
function Get-WorkingDays {
    param (
        [int]$year,
        [int]$month
    )

    $startDate = Get-Date -Year $year -Month $month -Day 1
    $endDate = $startDate.AddMonths(1).AddDays(-1)

    # Initialize an array to hold all days in the month
    $allDays = @()

    # Loop through each day in the month
    for ($date = $startDate; $date -le $endDate; $date = $date.AddDays(1)) {
        $allDays += $date
    }

    # Filter for working days (Monday to Friday)
    $workingDays = $allDays | Where-Object { $_.DayOfWeek -ne 'Saturday' -and $_.DayOfWeek -ne 'Sunday' }
    return $workingDays.Count
}

# Get the current year
$currentYear = (Get-Date).Year

# Display results for each month
for ($month = 1; $month -le 12; $month++) {
    $workingDays = Get-WorkingDays -year $currentYear -month $month

    if ($workingDays -gt 0) {
        # Calculate total hours for the month based on working days
        $totalHoursForMonth = $workingDays * $dailyHours
        
        # Calculate hours needed to achieve the desired percentage
        $hoursNeeded = $totalHoursForMonth * ($desiredPercentage / 100)

        # Calculate hours needed per day
        $hoursPerDay = $hoursNeeded / $workingDays

        Write-Host "Month: $([CultureInfo]::CurrentCulture.DateTimeFormat.GetMonthName($month))"
        Write-Host "Working Days: $workingDays"
        Write-Host "Total Hours for the Month: $totalHoursForMonth"
        Write-Host "Hours Needed to Achieve $desiredPercentage%: $hoursNeeded"
        Write-Host "Hours Needed per Day: $([math]::Round($hoursPerDay, 2))"
        Write-Host "---------------------------------------------"
    }
}
