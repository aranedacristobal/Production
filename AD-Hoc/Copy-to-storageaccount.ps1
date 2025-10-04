#Definera temp
$folderPath = "C:\temp"

#Kolla
if (-Not (Test-Path -Path $folderPath)) {
    # If it doesn't exist, create the folder
    New-Item -Path $folderPath -ItemType Directory
    Write-Host "Folder '$folderPath' created."
} else {
    Write-Host "Folder '$folderPath' already exists."
}

# Ta fram OS-info
$os = Get-CimInstance -ClassName Win32_OperatingSystem

# URL
$downloadUrl = "https://aka.ms/downloadazcopy-v10-windows"
# Nedlaggningssökväg
$outputFilePath = "C:\temp\azcopy.zip"

# Tvåväg
if ($os.BuildNumber -eq 14393) {
     Write-Host "Using bitsadmin to download AzCopy..."
    bitsadmin /transfer myDownloadJob /download /priority normal $downloadUrl $outputFilePath
} else {
      Write-Host "Using Invoke-WebRequest to download AzCopy..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFilePath
}

# Kontrollera
if (Test-Path $outputFilePath) {
    Write-Host "Download completed successfully: $outputFilePath"
} else {
    Write-Host "Download failed."
}

#Packa upp
Expand-Archive -Path "C:\temp\azcopy.zip" -DestinationPath "C:\temp\azcopy" -Force

#Hitta exe
Get-ChildItem -Path "C:\temp\azcopy" -Recurse -Filter "azcopy.exe"
$azcopyPath = Get-ChildItem -Path "C:\temp\azcopy" -Recurse -Filter "azcopy.exe" | Select-Object -ExpandProperty FullName

#Lägg azcopy.exe med i ENV Path
[System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";$azcopyPath", [System.EnvironmentVariableTarget]::Machine)

#Prompta för källa
$sourceUrl = Read-Host -Prompt "Enter the Source Path"

#Prompta för destination
$destinationPath = Read-Host -Prompt "Enter the Destination Path"


#Bygg ihop kommando
$command = "$azcopyPath sync `"$sourceUrl`" `"$destinationPath`" --recursive=true"

#Appenda 
$command >> "C:\temp\copy.ps1"
$Scriptpath = "C:\temp\copy.ps1"

#Skapa schemalagd task
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -File "C:\temp\copy.ps1"'
    #$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -File `"$scriptPath`"
    $trigger = New-ScheduledTaskTrigger -Daily -At '02:00AM'
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -TaskName "Azcopy migrering" -Description "Runs a PowerShell script to copy data from or to storage account"
