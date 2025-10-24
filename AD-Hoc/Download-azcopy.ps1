# Hämta den faktiska nedladdningslänken
$azcopyUrl = (Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -MaximumRedirection 0 -ErrorAction SilentlyContinue).Headers.Location

# Ladda ner AzCopy
Invoke-WebRequest -Uri $azcopyUrl -OutFile "azcopy.zip"

# Extrahera zip-filen
Expand-Archive -Path "azcopy.zip" -DestinationPath "./azcopy" -Force

# Hitta azcopy.exe
$azcopyExe = Get-ChildItem -Path "./azcopy" -Recurse -Filter "azcopy.exe" | Select-Object -First 1

# Skapa målmapp om den inte finns
$targetPath = "C:\Program Files\AzCopy"
if (!(Test-Path $targetPath)) {
    New-Item -ItemType Directory -Path $targetPath
}

# Kopiera azcopy.exe till målmappen
Copy-Item -Path $azcopyExe.FullName -Destination "$targetPath\azcopy.exe" -Force

# Lägg till sökvägen i systemets PATH
$existingPath = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
if ($existingPath -notlike "*C:\Program Files\AzCopy*") {
    $newPath = "$existingPath;C:\Program Files\AzCopy"
    [Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
}

# Rensa temporära filer
Remove-Item -Path "azcopy.zip" -Force
Remove-Item -Path "./azcopy" -Recurse -Force

Write-Host "AzCopy har installerats och lagts till i systemets PATH."
