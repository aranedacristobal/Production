# AzCopy Auto-Install Script for Windows
# Run as Administrator for system-wide installation

param(
    [switch]$CurrentUserOnly = $false
)

Write-Host "Starting AzCopy installation..." -ForegroundColor Green

# Download AzCopy
$downloadUrl = "https://aka.ms/downloadazcopy-v10-windows"
$zipFile = "azcopy.zip"
$extractPath = ".\azcopy_temp"

Write-Host "Downloading AzCopy..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
    Write-Host "Download completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error downloading AzCopy: $_" -ForegroundColor Red
    exit 1
}

# Extract AzCopy
Write-Host "Extracting AzCopy..." -ForegroundColor Yellow
try {
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
    }
    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
    Write-Host "Extraction completed!" -ForegroundColor Green
}
catch {
    Write-Host "Error extracting AzCopy: $_" -ForegroundColor Red
    exit 1
}

# Find the azcopy.exe
$azcopyFolders = Get-ChildItem -Path $extractPath -Directory -Filter "azcopy_windows_*"
if ($azcopyFolders.Count -eq 0) {
    Write-Host "Could not find AzCopy folder in extracted contents" -ForegroundColor Red
    exit 1
}

$azcopyFolder = $azcopyFolders[0].FullName
$azcopyExePath = Join-Path $azcopyFolder "azcopy.exe"

if (-not (Test-Path $azcopyExePath)) {
    Write-Host "azcopy.exe not found in expected location" -ForegroundColor Red
    exit 1
}

Write-Host "AzCopy found at: $azcopyExePath" -ForegroundColor Green

# Installation directory
$installDir = "C:\Program Files\AzCopy"
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# Copy AzCopy to program files
Write-Host "Installing AzCopy to $installDir..." -ForegroundColor Yellow
Copy-Item $azcopyExePath $installDir -Force
Write-Host "AzCopy installed to program files!" -ForegroundColor Green

# Add to Environment Variables
Write-Host "Adding AzCopy to PATH..." -ForegroundColor Yellow

if (-not $CurrentUserOnly -and ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator for system-wide installation" -ForegroundColor Red
    Write-Host "Or use -CurrentUserOnly flag for current user installation" -ForegroundColor Yellow
    $CurrentUserOnly = $true
}

if ($CurrentUserOnly) {
    # Current user only
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -split ";" -notcontains $installDir) {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installDir", "User")
        Write-Host "Added to current user PATH" -ForegroundColor Green
    }
} else {
    # System-wide installation
    $systemPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($systemPath -split ";" -notcontains $installDir) {
        [Environment]::SetEnvironmentVariable("Path", "$systemPath;$installDir", "Machine")
        Write-Host "Added to system PATH" -ForegroundColor Green
    }
}

# Cleanup
Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

# Verify installation
Write-Host "`nVerifying installation..." -ForegroundColor Cyan
Write-Host "Please open a NEW command prompt and run: azcopy --version" -ForegroundColor Yellow
Write-Host "Or run this command to test in current session:" -ForegroundColor Yellow

# Refresh environment in current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Test if azcopy is accessible
try {
    $version = & "$installDir\azcopy.exe" --version
    Write-Host "`nAzCopy installation verified!" -ForegroundColor Green
    Write-Host "Version: $version" -ForegroundColor White
}
catch {
    Write-Host "`nAzCopy installed but may require a new command prompt to be accessible" -ForegroundColor Yellow
}

Write-Host "`nInstallation completed!" -ForegroundColor Green
