# Variabler 
#------------------------------------------------------------------------------------------------------------------------------------#

# Definiera URL:en för nedladdning 
$repoUrl = "https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip"

# Definiera sökvägarna
$downloadPath = "c:\VirtualDesktopOptimizationTool.zip"
$extractPath = "c:\VDOT\"

#Exekevring 
#------------------------------------------------------------------------------------------------------------------------------------#

# Skapa katalog för extrahera ZIP:ade filen
    if (!(Test-Path -Path $extractPath)) {
        New-Item -ItemType Directory -Path $extractPath -Force
}

# Ladda ner Zip:ade filen
    Write-Output "Downloading Virtual Desktop Optimization Tool from GitHub..."
    Invoke-WebRequest -Uri $repoUrl -OutFile $downloadPath

# Extrahera ZIP:ade filen
    Write-Output "Extracting files..."
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($downloadPath, $extractPath)

# Ta bort ZIP:ade filen
    Remove-Item -Path $downloadPath -Force
    Write-Output "Virtual Desktop Optimization Tool downloaded and extracted to: $extractPath"

# Ändra executionpolicy
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
  
# Kör skript
    powershell  ""$extractPath\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1 -Optimizations All -AdvancedOptimizations All -AcceptEULA -Verbose""cd 