# Read the configuration file
$config = Get-Content -Path "C:\temp\config.json" | ConvertFrom-Json
$apiKey = $config.APIKey

# Define the API URL
$apiUrl = "https://calendarific.com/api/v2/holidays?&api_key=$apiKey&country=SE&year=2025"

# Fetch the holiday data
$response = Invoke-RestMethod -Uri $apiUrl -Method Get

# Check if the response contains holidays
if ($response.meta.code -eq 200 -and $response.response.holidays) {
    # Loop through each holiday and display the relevant information
    foreach ($holiday in $response.response.holidays) {
        $holidayDate = $holiday.date.iso
        $holidayName = $holiday.name
        $holidayDescription = $holiday.description

        Write-Host "Date: $holidayDate"
        Write-Host "Holiday: $holidayName"
        Write-Host "Description: $holidayDescription"
        Write-Host "---------------------------------------------"
    }
} else {
    Write-Host "No holidays found or an error occurred."
}