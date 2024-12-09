Start-Transcript (Join-Path $env:TEMP 'Install-Azure-VPN.log')

# Define a marker file path
$markerFilePath = Join-Path $env:TEMP 'AzureVPN_Install_Marker.txt'

#Check if the script has already been run
if (Test-Path $markerFilePath) {
    Write-Host "Script has already been run. Exiting."
    exit
}

# Install winget
Install-PackageProvider -Name NuGet -Force | Out-Null
Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
Repair-WinGetPackageManager -IncludePrerelease

# Install Azure VPN
winget install "azure vpn" --accept-package-agreements --accept-source-agreements

# Chill
Start-Sleep -Seconds 30

# Get config file from netlogon and dump it in the user's local
$username = $env:USERNAME

# Variables
$fullPath = "C:\Users\$username\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState"
$sourceFile = "\\DOMAIN.LOCAL\NETLOGON\Azure-vpn\rasphone.pbk" 

# Execute
Copy-Item -Path $sourceFile -Destination $fullPath -Force
Write-Output "File copied to $fullPath"

# Create the marker file to indicate the script has run
New-Item -Path $markerFilePath -ItemType File -Force | Out-Null

Stop-Transcript
