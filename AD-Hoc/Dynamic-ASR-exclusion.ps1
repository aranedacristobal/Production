#Definiera sökväg och app

$exePath = Get-ChildItem -Path "C:\Program Files (x86)\" -Filter "NinjaRMMAgent.exe" -Recurse | Select-Object -First 1
if ($exePath) {
    Add-MpPreference -AttackSurfaceReductionOnlyExclusions $exePath.FullName
}