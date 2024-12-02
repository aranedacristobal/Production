# Funktion för att kolla om Winget är installerad
function Check-Winget {
    try {
        # Kolla 
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
    Remove-Item -Path $installerPath -Force

    Write-Host "winget installation klar."
}

# Exekvera
if (-not (Check-Winget)) {
    Install-Winget
} else {
    Write-Host "Inget behövs. winget är redan installerad."
}

# Installera Az-VPN

winget install "azure vpn" --accept-package-agreements --accept-source-agreements
