# Kolla om temp finns
if (!(Test-Path -Path "C:\temp")) {
    New-Item -ItemType Directory -Path "C:\temp"
}

# Speca URL
$scriptUrl = "https://raw.githubusercontent.com/aranedacristobal/lab/refs/heads/main/Dynamic-ASR-exclusion.ps1"
$destinationPath = "C:\temp\NinjaASR.ps1"

# Hämta skript
    Invoke-WebRequest -Uri $scriptUrl -OutFile $destinationPath

#Skapa schemalagd task
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -File "C:\temp\NinjaASR.ps1"'
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings -TaskName "Add NinjaOne ASR Exclusion" -Description "Runs a PowerShell script to add NinjaOne ASR exclusion"