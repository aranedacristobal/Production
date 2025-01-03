# Trigga powerkjellskript

& 'Ninja\Ninja-automation\List\Locations\Ninja-token.ps1'

Start-Sleep -Seconds 10

& 'Ninja\Ninja-automation\List\Organisations\Ninja-token.ps1'

Start-Sleep -Seconds 15

# Importera
$csvPath1 = "Ninja\Ninja-automation\List\Locations\locations.csv"  # Change this to your second input CSV file path
$csvPath2 = "Ninja\Ninja-automation\List\Organisations\organisations.csv"  # Change this to your first input CSV file path
$outputPath = "Ninja\Ninja-automation\List\output2.csv"  # Change this to your desired output CSV file path

# Läs in
$data1 = Import-Csv -Path $csvPath1
$data2 = Import-Csv -Path $csvPath2

# Loopa
foreach ($record2 in $data2) {
    # Hitta matcher uppslag i första CSV baserat på organizationId
    $matchingRecord = $data1 | Where-Object { $_.organizationId -eq $record2.organizationid } | Select-Object -First 1
    
        # Om matcher hittas uppdatera i andra csv
    if ($matchingRecord) {
        $record2.id = $matchingRecord.id 
    }
}

# Tvätta
$modifiedData = $data2 | Select-Object name, 
    @{Name='locationid'; Expression={$_.id}},  
    organizationid

# Exportera 
$modifiedData | Export-Csv -Path $outputPath -NoTypeInformation -Delimiter ','