Write-Host "Baixando pacote SSH..." -ForegroundColor Cyan

# URL do ZIP do repositório
$zipUrl = "https://github.com/jhoylsonn/Install_SSH/archive/refs/heads/main.zip"

# Caminhos temporários
$tempZip = "$env:TEMP\Install_SSH.zip"
$tempDir = "$env:TEMP\Install_SSH"

# Baixar ZIP usando BITS (muito mais rápido e estável)
Start-BitsTransfer -Source $zipUrl -Destination $tempZip

# Extrair ZIP
Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

# Caminho da pasta SSH dentro do ZIP
$sshPath = Join-Path $tempDir "Install_SSH-main\SSH"

# Verificar se a pasta existe
if (-not (Test-Path $sshPath)) {
    Write-Host "Erro: Pasta SSH não encontrada dentro do repositório!" -ForegroundColor Red
    exit
}

# Menu interativo
Clear-Host
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "      INSTALADOR REMOTO DO OPENSSH        " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1 - Instalar OpenSSH"
Write-Host "2 - Desinstalar OpenSSH"
Write-Host "0 - Sair"
Write-Host ""
$op = Read-Host "Escolha uma opção"

switch ($op) {
    "1" {
        Write-Host "Executando instalador..." -ForegroundColor Cyan
        & "$sshPath\Script_InstallSSH.ps1"
    }
    "2" {
        Write-Host "Executando desinstalador..." -ForegroundColor Cyan
        & "$sshPath\Uninstall_OpenSSH.ps1"
    }
    "0" {
        Write-Host "Saindo..." -ForegroundColor Yellow
        exit
    }
    default {
        Write-Host "Opção inválida!" -ForegroundColor Red
    }
}

# Limpeza opcional
Remove-Item $tempZip -Force
Remove-Item $tempDir -Recurse -Force
