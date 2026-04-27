Write-Host "Baixando pacote SSH..." -ForegroundColor Cyan

# URL do ZIP do repositório
$zipUrl = "https://github.com/jhoylsonn/Install_SSH/archive/refs/heads/main.zip"

# Caminhos temporários
$tempZip = "$env:TEMP\Install_SSH.zip"
$tempDir = "$env:TEMP\Install_SSH"

# Remover restos anteriores
if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }

# Baixar ZIP usando BITS
Start-BitsTransfer -Source $zipUrl -Destination $tempZip

# Garantir que o arquivo realmente existe
if (-not (Test-Path $tempZip)) {
    Write-Host "Erro: download falhou!" -ForegroundColor Red
    exit
}

# Criar pasta temporária
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Extrair ZIP usando .NET (método mais confiável)
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($tempZip, $tempDir)

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
$op = Read-Host "Escolha uma opcao"

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
        Write-Host "Opção invalida!" -ForegroundColor Red
    }
}

# Limpeza opcional
Remove-Item $tempZip -Force
Remove-Item $tempDir -Recurse -Force
