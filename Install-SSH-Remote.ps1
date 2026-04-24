Write-Host "Baixando instalador SSH..."

<<<<<<< HEAD
$script = "https://raw.githubusercontent.com/jhoylsonn/Install_SSH/refs/heads/main/SSH/Script_InstallSSH.ps1"
=======
$script = "https://raw.githubusercontent.com/jhoylsonn/Install_SSH/refs/heads/main/Script_InstallSSH.ps1"
>>>>>>> 15934a30e71bcbdd0b9cb66f2b5cb8919e77ea76

Invoke-WebRequest -UseBasicParsing $script -OutFile "$env:TEMP\Script_InstallSSH.ps1"

Write-Host "Executando instalador..."
& "$env:TEMP\Script_InstallSSH.ps1"
