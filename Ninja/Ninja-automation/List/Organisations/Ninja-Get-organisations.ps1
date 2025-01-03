"------------------------------------------------------------------------------------------------------------------------------------------------"
"------------------------------------------------------------------------------------------------------------------------------------------------"

# Variables
$url = "YOUR _URL FOR GET ORGANISATIONS" # URL 

# Define header
$headers = @{
    "Accept"        = "application/json"
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

$response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers 

"------------------------------------------------------------------------------------------------------------------------------------------------"
"------------------------------------------------------------------------------------------------------------------------------------------------"

Start-Sleep -Seconds 2

$response | Export-Csv -Path "Ninja\Ninja-automation\List\Organisations\organisations-temp.csv" -NoTypeInformation

# Import
$csvPath = "Ninja\Ninja-automation\List\Organisations\organisations-temp.csv"  
$outputPath = "Ninja\Ninja-automation\List\Organisations\organisations.csv"  

# Read
$data = Import-Csv -Path $csvPath

Start-Sleep -Seconds 5

$modifiedData = $data | Select-Object name, 
    @{Name='id'; Expression={""}},  
    @{Name='organizationid'; Expression={$_.id}}  

# Export
$modifiedData | Export-Csv -Path $outputPath -NoTypeInformation -Delimiter ','