Start-Transcript (Join-Path $env:TEMP 'Install-Azure-VPN.log')

# Funktion för att kolla om Winget är installerad
function Test-WingetInstalled {
    try {
        $winget = Get-Command winget -ErrorAction Stop
        Write-Host "winget är installerad. Version: $($winget.FileVersionInfo.FileVersion)"
        return $true
    } catch {
        Write-Host "winget är inte installerad."
        return $false
    }
}

# Funktion för att installera Winget
function Install-Winget {
    Write-Host "Installerar winget..."
    
    # Skapa variabler för o dumpa i temp
    $installerUrl = "https://aka.ms/getwinget"
    $installerPath = "$env:TEMP\AppInstaller.msixbundle"

    # Ladda ner winget
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

    # Installera 
    Add-AppxPackage -Path $installerPath

    # Steka
    #Remove-Item -Path $installerPath -Force

    Write-Host "winget installation klar."
}

# Exekvera
if (-not (Test-WingetInstalled)) {
    Install-Winget
} else {
    Write-Host "Inget behövs. winget är redan installerad."
}

# Installera Az-VPN
winget install "azure vpn" --accept-package-agreements --accept-source-agreements

# Chilla
Start-Sleep -Seconds 30

# Hämta konfigfil från netlogon o dumpa i användarens local
$username = $env:USERNAME

# Variabler
$fullPath = "C:\Users\$username\AppData\Local\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe\LocalState"
$sourceFile = "\\YOURDOMAIN.LOCAL\NETLOGON\Azure-vpn\rasphone.pbk" 

# Exekvera
Copy-Item -Path $sourceFile -Destination $fullPath -Force
Write-Output "Fil kopierad to $fullPath"

Stop-Transcript
