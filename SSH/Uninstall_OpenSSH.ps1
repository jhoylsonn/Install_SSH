<# 
    Script: Uninstall_OpenSSH.ps1
    Função:
      - Detectar tipo de instalação do OpenSSH (Windows Capability ou Manual)
      - Remover serviços sshd e ssh-agent
      - Remover firewall, pastas e PATH
      - Gerar log detalhado
#>

# ==========================
# CONFIGURAÇÕES INICIAIS
# ==========================
$ErrorActionPreference = "Stop"
$logFile = "$PSScriptRoot\UninstallSSH_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

Write-Log "====================================="
Write-Log " INÍCIO DO SCRIPT DE DESINSTALAÇÃO SSH "
Write-Log "====================================="

# ==========================
# VERIFICAR EXECUÇÃO COMO ADMIN
# ==========================
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "Este script deve ser executado como Administrador." "ERROR"
    Read-Host "Pressione ENTER para sair"
    exit 1
}

# ==========================
# DETECTAR INSTALAÇÃO VIA WINDOWS CAPABILITY
# ==========================
Write-Log "Verificando instalação via Windows Capability..."

$cap = Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH.Server~~~~0.0.1.0" }

$installedByWindows = $false
if ($cap -and $cap.State -eq "Installed") {
    $installedByWindows = $true
    Write-Log "OpenSSH instalado via Windows Capability."
}
else {
    Write-Log "OpenSSH NÃO está instalado via Windows Capability."
}

# ==========================
# REMOVER INSTALAÇÃO VIA WINDOWS CAPABILITY
# ==========================
if ($installedByWindows) {
    Write-Log "Removendo OpenSSH.Server via Windows Capability..."

    try {
        Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        Write-Log "OpenSSH removido via Windows Capability."
    }
    catch {
        Write-Log "Falha ao remover Windows Capability: $($_.Exception.Message)" "ERROR"
    }
}

# ==========================
# REMOVER SERVIÇOS (MANUAL OU ONLINE)
# ==========================
Write-Log "Removendo serviços sshd e ssh-agent..."

$services = @("sshd", "ssh-agent")

foreach ($svc in $services) {
    try {
        if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
            Write-Log "Parando serviço $svc..."
            Stop-Service $svc -Force -ErrorAction SilentlyContinue

            Write-Log "Removendo serviço $svc..."
            sc.exe delete $svc | Out-Null
        }
        else {
            Write-Log "Serviço $svc não encontrado."
        }
    }
    catch {
        Write-Log "Erro ao remover serviço ${svc}: $($_.Exception.Message)" "WARN"
    }
}

# ==========================
# REMOVER FIREWALL
# ==========================
Write-Log "Removendo regra de firewall..."

try {
    Remove-NetFirewallRule -DisplayName "OpenSSH SSH Server" -ErrorAction SilentlyContinue
    Write-Log "Regra de firewall removida."
}
catch {
    Write-Log "Erro ao remover regra de firewall: $($_.Exception.Message)" "WARN"
}

# ==========================
# REMOVER PASTA DE INSTALAÇÃO MANUAL
# ==========================
$installDir = "C:\Program Files\OpenSSH"

if (Test-Path $installDir) {
    Write-Log "Removendo pasta de instalação manual: $installDir"

    try {
        Remove-Item $installDir -Recurse -Force
        Write-Log "Pasta removida com sucesso."
    }
    catch {
        Write-Log "Erro ao remover pasta: $($_.Exception.Message)" "ERROR"
    }
}
else {
    Write-Log "Pasta de instalação manual não encontrada."
}

# ==========================
# REMOVER PATH DO SISTEMA
# ==========================
Write-Log "Removendo OpenSSH do PATH do sistema..."

try {
    $envPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($envPath -like "*C:\Program Files\OpenSSH*") {
        $newPath = $envPath -replace "C:\\Program Files\\OpenSSH;",""
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
        Write-Log "PATH atualizado."
    }
    else {
        Write-Log "OpenSSH não estava no PATH."
    }
}
catch {
    Write-Log "Erro ao atualizar PATH: $($_.Exception.Message)" "WARN"
}

# ==========================
# FINALIZAÇÃO
# ==========================
Write-Log "====================================="
Write-Log " DESINSTALAÇÃO DO OPENSSH CONCLUÍDA "
Write-Log "====================================="

Write-Host ""
Write-Host "Desinstalação concluída."
Write-Host "Log salvo em: $logFile"
Write-Host ""
Read-Host "Pressione ENTER para sair"