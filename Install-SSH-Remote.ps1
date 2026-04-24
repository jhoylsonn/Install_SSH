Write-Host "Baixando instalador SSH..."

$script = "https://raw.githubusercontent.com/jhoylsonn/Install_SSH/refs/heads/main/SSH/Script_InstallSSH.ps1"

Invoke-WebRequest -UseBasicParsing $script -OutFile "$env:TEMP\Script_InstallSSH.ps1"

Write-Host "Executando instalador..."
& "$env:TEMP\Script_InstallSSH.ps1"
