$repo = "https://raw.githubusercontent.com/jhoylsonn/Install_SSH/main"

Write-Host "Baixando instalador SSH..."

$script = "$repo/Script_InstallSSH.ps1"
Invoke-WebRequest $script -OutFile "$env:TEMP\Script_InstallSSH.ps1"

Write-Host "Executando instalador..."
& "$env:TEMP\Script_InstallSSH.ps1"
