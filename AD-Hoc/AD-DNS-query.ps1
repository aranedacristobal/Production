# Import required module
Import-Module DnsServer -ErrorAction SilentlyContinue
if (-not (Get-Module -Name DnsServer)) {
    Write-Host "DNS Server module not found. Please install RSAT tools." -ForegroundColor Red
    exit
}

# Parameters
$DNSZone = "contoso.com"  # Change to your DNS zone
$OutputFile = "C:\temp\$DNSZone-DNS_Ping_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$PingCount = 1  # Number of ping attempts
$PingBufferSize = 32  # Bytes
$PingDelay = 60  # Milliseconds between pings (when Count > 1)

# Get DNS records from the specified zone
try {
    $DNSRecords = Get-DnsServerResourceRecord -ZoneName $DNSZone -ErrorAction Stop | 
                  Where-Object {$_.RecordType -eq "A" -or $_.RecordType -eq "CNAME"}
    
    if (-not $DNSRecords) {
        Write-Host "No DNS records found in zone $DNSZone" -ForegroundColor Yellow
        exit
    }
}
catch {
    Write-Host "Error retrieving DNS records: $_" -ForegroundColor Red
    exit
}

# Initialize results array
$Results = @()

# Process each record
foreach ($Record in $DNSRecords) {
    $RecordName = $Record.HostName
    $RecordType = $Record.RecordType
    $RecordData = if ($RecordType -eq "A") { $Record.RecordData.IPv4Address.IPAddressToString } 
                  else { $Record.RecordData.HostNameAlias }
    
    # Create ping test object
    $TestResult = [PSCustomObject]@{
        HostName       = $RecordName
        RecordType     = $RecordType
        RecordData     = $RecordData
        TimeStamp      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    # Ping test (for A records only)
    if ($RecordType -eq "A") {
        try {
            # Using fully compatible Test-Connection syntax
            $Ping = Test-Connection -ComputerName $RecordData -Count $PingCount -BufferSize $PingBufferSize -Delay $PingDelay -ErrorAction Stop
            
            $TestResult | Add-Member -NotePropertyName "Status" -NotePropertyValue "Success"
            $TestResult | Add-Member -NotePropertyName "ResponseTime" -NotePropertyValue $Ping.ResponseTime
            Write-Host "Success: $RecordName ($RecordData)" -ForegroundColor Green
        }
        catch {
            $TestResult | Add-Member -NotePropertyName "Status" -NotePropertyValue "Failed"
            $TestResult | Add-Member -NotePropertyName "ResponseTime" -NotePropertyValue $null
            $TestResult | Add-Member -NotePropertyName "ErrorDetails" -NotePropertyValue $_.Exception.Message
            Write-Host "Failed: $RecordName ($RecordData)" -ForegroundColor Red
        }
    }
    else {
        $TestResult | Add-Member -NotePropertyName "Status" -NotePropertyValue "CNAME - Not Tested"
        $TestResult | Add-Member -NotePropertyName "ResponseTime" -NotePropertyValue $null
        $TestResult | Add-Member -NotePropertyName "ErrorDetails" -NotePropertyValue $null
        Write-Host "CNAME: $RecordName points to $RecordData" -ForegroundColor Cyan
    }

    # Add to results
    $Results += $TestResult

    # Small delay between hosts
    Start-Sleep -Milliseconds 200
}

# Export results to CSV
try {
    $Results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
    Write-Host "`nResults exported to $OutputFile" -ForegroundColor Green
    Write-Host "Total records processed: $($Results.Count)" -ForegroundColor Green
    Write-Host "Success: $($Results | Where-Object {$_.Status -eq 'Success'}).Count)" -ForegroundColor Green
    Write-Host "Failed: $($Results | Where-Object {$_.Status -eq 'Failed'}).Count)" -ForegroundColor Red
    if ($Results | Where-Object {$_.Status -eq 'Failed'}) {
        Write-Host "`nFailed hosts:" -ForegroundColor Yellow
        $Results | Where-Object {$_.Status -eq 'Failed'} | ForEach-Object {
            Write-Host "$($_.HostName) ($($_.RecordData)) - $($_.ErrorDetails)" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "Error exporting results: $_" -ForegroundColor Red
}

# Open the results file if desired
$OpenFile = Read-Host "`nWould you like to open the results file now? (Y/N)"
if ($OpenFile -eq "Y" -or $OpenFile -eq "y") {
    try {
        Start-Process $OutputFile
    }
    catch {
        Write-Host "Could not open the file automatically. Please open $OutputFile manually." -ForegroundColor Yellow
    }
}
