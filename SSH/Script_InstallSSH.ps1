<#
Script: Script_InstallSSH.ps1
Função:
- Instalar e configurar OpenSSH Server com prioridade para ZIP local
- Se não houver ZIP local, tentar instalação online (Windows Capability)
- Se falhar, fazer download do GitHub como último recurso
- Detectar múltiplos IPs válidos
- Testar porta 22 em cada IP
- Criar regra de firewall
- Exibir mensagens amigáveis e logs
#>

$ErrorActionPreference = "Stop"

# ==========================
# CONFIGURAÇÕES INICIAIS
# ==========================

$logFile = Join-Path -Path $PSScriptRoot -ChildPath ("{0}.txt" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    Write-Host $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8
}

Write-Log "="
Write-Log " INÍCIO DO SCRIPT DE INSTALAÇAO SSH "
Write-Log "="

# ==========================
# VERIFICAR EXECUÇÃO COMO ADMIN
# ==========================

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Log "Este script deve ser executado como Administrador." "ERROR"
    Read-Host "Pressione ENTER para sair"
    exit 1
}

# ==========================
# DEFINIR POLÍTICA DE EXECUÇAO
# ==========================

try {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force
    Write-Log "Política de execução definida como: Unrestricted"
}
catch {
    Write-Log ("Falha ao definir política de execuçao: {0}" -f $_.Exception.Message) "WARN"
}

# ==========================
# FUNÇÃO: VERIFICAR SE OPENSSH SERVER ESTA INSTALADO
# ==========================

function Test-OpenSSHInstalled {
    try {
        $cap = Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH.Server~~~~0.0.1.0" }
        return ($cap -and $cap.State -eq "Installed")
    }
    catch {
        Write-Log ("Erro ao verificar capacidade OpenSSH.Server: {0}" -f $_.Exception.Message) "WARN"
        return $false
    }
}

# ==========================
# FUNÇÃO: INSTALAR OPENSSH (ONLINE)
# ==========================

function Install-OpenSSHOnline {
    Write-Log "Tentando instalar OpenSSH Server (modo ONLINE)..."
    try {
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        Write-Log "Instalaçao ONLINE do OpenSSH concluida com sucesso."
        return $true
    }
    catch {
        Write-Log ("Falha na instalação ONLINE do OpenSSH: {0}" -f $_.Exception.Message) "WARN"
        return $false
    }
}

# ==========================
# FUNÇÃO: INSTALAR OPENSSH (PRIORIDADE ZIP LOCAL -> ONLINE -> GITHUB)
# ==========================

function Install-OpenSSHManual {
    Write-Log "Tentando instalar OpenSSH Server (prioridade: ZIP local)..."

    $url = "https://github.com/PowerShell/Win32-OpenSSH/releases/latest/download/OpenSSH-Win64.zip"
    $zipLocal = Join-Path $PSScriptRoot "OpenSSH-Win64.zip"
    $zipTemp = Join-Path $env:TEMP "OpenSSH-Win64.zip"
    $installDir = "C:\Program Files\OpenSSH"

    # ------------------------------------------------------------
    # 1) PRIORIDADE MÁXIMA → INSTALAÇÃO VIA ZIP LOCAL
    # ------------------------------------------------------------
    if (Test-Path $zipLocal) {
        Write-Log "Pacote local encontrado: $zipLocal"
        Write-Log "Tentando instalar a partir do ZIP local..."

        try {
            if (-not (Test-Path $installDir)) {
                New-Item -Path $installDir -ItemType Directory -Force | Out-Null
            }

            Expand-Archive -Path $zipLocal -DestinationPath $installDir -Force
            Write-Log "Extraçao concluida a partir do ZIP local."

            # Detecta subpasta interna e move conteúdo para a raiz
            $innerFolder = Get-ChildItem -Path $installDir -Directory | Select-Object -First 1
            if ($innerFolder) {
                Write-Log "Subpasta detectada dentro do ZIP local: $($innerFolder.FullName)"
                Get-ChildItem -Path $innerFolder.FullName -Recurse | Move-Item -Destination $installDir -Force
                Remove-Item -Path $innerFolder.FullName -Recurse -Force
            }

            $installScript = Join-Path $installDir "install-sshd.ps1"
            if (Test-Path $installScript) {
                Write-Log "Executando script de instalaçao local..."
                & $installScript
            }
            else {
                Write-Log "install-sshd.ps1 nao encontrado apos extraçao local." "ERROR"
                return $false
            }

            Set-Service sshd -StartupType Automatic
            Start-Service sshd

            Write-Log "Instalaçao concluida com sucesso usando o ZIP local."
            return $true
        }
        catch {
            Write-Log ("Falha ao instalar a partir do ZIP local: {0}" -f $_.Exception.Message) "WARN"
        }
    }
    else {
        Write-Log "Nenhum pacote local encontrado em $zipLocal"
    }

    # ------------------------------------------------------------
    # 2) SEGUNDA OPÇÃO → INSTALAÇÃO ONLINE
    # ------------------------------------------------------------
    Write-Log "Tentando instalação ONLINE..."

    try {
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
        Write-Log "Instalação ONLINE concluída com sucesso."
        return $true
    }
    catch {
        Write-Log ("Falha na instalaçao ONLINE: {0}" -f $_.Exception.Message) "WARN"
    }

    # ------------------------------------------------------------
    # 3) ÚLTIMA OPÇÃO → DOWNLOAD DO GITHUB
    # ------------------------------------------------------------
    Write-Log "Tentando fallback manual via GitHub..."

    try {
        Write-Log "Baixando pacote OpenSSH do GitHub..."
        Invoke-WebRequest -Uri $url -OutFile $zipTemp -UseBasicParsing

        if (-not (Test-Path $installDir)) {
            New-Item -Path $installDir -ItemType Directory -Force | Out-Null
        }

        Expand-Archive -Path $zipTemp -DestinationPath $installDir -Force
        Write-Log "Extraçao concluida via GitHub."

        # Detecta subpasta interna e move conteúdo para a raiz
        $innerFolder = Get-ChildItem -Path $installDir -Directory | Select-Object -First 1
        if ($innerFolder) {
            Write-Log "Subpasta detectada dentro do ZIP do GitHub: $($innerFolder.FullName)"
            Get-ChildItem -Path $innerFolder.FullName -Recurse | Move-Item -Destination $installDir -Force
            Remove-Item -Path $innerFolder.FullName -Recurse -Force
        }

        $installScript = Join-Path $installDir "install-sshd.ps1"
        if (Test-Path $installScript) {
            Write-Log "Executando install-sshd.ps1 (GitHub)..."
            & $installScript
        }
        else {
            Write-Log "install-sshd.ps1 não encontrado após extração do GitHub." "ERROR"
            return $false
        }

        Set-Service sshd -StartupType Automatic
        Start-Service sshd

        Write-Log "Instalaçao concluida via GitHub."
        return $true
    }
    catch {
        Write-Log ("Falha no fallback via GitHub: {0}" -f $_.Exception.Message) "ERROR"
    }

    Write-Log "Falha total na instalaçao do OpenSSH (ZIP local, ONLINE e GitHub)." "ERROR"
    return $false
}

# ==========================
# FUNÇÃO: GARANTIR SERVIÇO SSHD
# =======================
function Ensure-SshdRunning {
    try {
        $svc = Get-Service -Name sshd -ErrorAction Stop
        if ($svc.StartType -ne 'Automatic') {
            Set-Service sshd -StartupType Automatic
        }
        if ($svc.Status -ne 'Running') {
            Start-Service sshd
        }
        Write-Log "Serviço sshd configurado como Automático e em execuçao."
        return $true
    }
    catch {
        Write-Log ("Serviço sshd não encontrado ou não pôde ser iniciado: {0}" -f $_.Exception.Message) "ERROR"
        return $false
    }
}

# ==========================
# FUNÇÃO: TESTAR PORTA 22 EM UM IP
# ==========================

function Test-SshPort {
    param(
        [Parameter(Mandatory=$true)][string]$IpAddress,
        [int]$Port = 22
    )
    try {
        $result = Test-NetConnection -ComputerName $IpAddress -Port $Port -WarningAction SilentlyContinue
        return [bool]$result.TcpTestSucceeded
    }
    catch {
        return $false
    }
}

# ==========================
# ETAPA 1: VERIFICAR / INSTALAR OPENSSH
# ==========================

Write-Host ""
Write-Host "=== Verificando instalaçao do OpenSSH Server ==="
Write-Log "Verificando se OpenSSH Server já esta instalado..."

$sshInstalled = Test-OpenSSHInstalled
if (-not $sshInstalled) {
    Write-Host "OpenSSH Server não encontrado. Instalando..."
    Write-Log "OpenSSH Server não encontrado. Iniciando processo de instalaçao..."

    # Tenta ONLINE primeiro? -> aqui seguimos sua regra: prioridade ZIP local
    $installed = Install-OpenSSHManual
    if (-not $installed) {
        Write-Log "Instalaçao manual/online falhou. Tentando modo ONLINE direto..." "WARN"
        $installed = Install-OpenSSHOnline
    }

    if (-not $installed) {
        Write-Log "Não foi possível instalar o OpenSSH Server." "ERROR"
        Write-Host "Falha total ao instalar o OpenSSH Server. Veja o log: $logFile"
        Read-Host "Pressione ENTER para sair"
        exit 1
    }
}
else {
    Write-Host "OpenSSH Server já esta instalado."
    Write-Log "OpenSSH Server já estava instalado."
}

# ==========================
# ETAPA 2: INICIAR E CONFIGURAR SERVIÇO SSHD
# ==========================

Write-Host ""
Write-Host "=== Iniciando e configurando o serviço SSHD ==="
Write-Log "Configurando serviço sshd..."

if (-not (Ensure-SshdRunning)) {
    Write-Host "Serviço sshd não foi encontrado ou nao iniciou. Verifique a instalaçao do OpenSSH."
    Write-Host "Log: $logFile"
    Read-Host "Pressione ENTER para sair"
    exit 1
}

# ==========================
# ETAPA 3: CONFIGURAR FIREWALL
# ==========================

Write-Host ""
Write-Host "=== Configurando Firewall ==="
Write-Log "Configurando regra de firewall para porta 22..."

try {
    $rule = Get-NetFirewallRule -DisplayName "OpenSSH SSH Server" -ErrorAction SilentlyContinue
    if (-not $rule) {
        New-NetFirewallRule -Name "sshd" -DisplayName "OpenSSH SSH Server" -Enabled True `
            -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
        Write-Host "Regra de firewall criada."
        Write-Log "Regra de firewall 'OpenSSH SSH Server' criada."
    }
    else {
        Write-Host "Regra de firewall já existe."
        Write-Log "Regra de firewall 'OpenSSH SSH Server' ja existia."
    }
}
catch {
    Write-Log ("Erro ao configurar firewall: {0}" -f $_.Exception.Message) "ERROR"
    Write-Host "Erro ao configurar o firewall."
}

Write-Host ""
Write-Host "Aguardando serviço estabilizar..."
Start-Sleep -Seconds 5

# ==========================
# ETAPA 4: OBTER IPs VÁLIDOS
# ==========================

Write-Host ""
Write-Host "=== Obtendo IPs validos da maquina ==="
Write-Log "Obtendo IPs IPv4 (interfaces ativas)..."

try {
    $ips = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notlike "169.*" -and
            $_.IPAddress -ne "127.0.0.1" -and
            $_.PrefixOrigin -ne "WellKnown" -and
            $_.ValidLifetime -gt 0
        } |
        Select-Object -ExpandProperty IPAddress -Unique
}
catch {
    Write-Log ("Erro ao obter IPs: {0}" -f $_.Exception.Message) "ERROR"
    Write-Host "Erro ao obter IPs da maquina."
    Read-Host "Pressione ENTER para sair"
    exit 1
}

if (-not $ips -or $ips.Count -eq 0) {
    Write-Log "Nenhum IPv4 valido encontrado." "ERROR"
    Write-Host "Nenhum IP valido encontrado."
    Write-Host "Log: $logFile"
    Read-Host "Pressione ENTER para sair"
    exit 1
}

Write-Log ("IPs encontrados: {0}" -f ($ips -join ', '))

# ==========================
# ETAPA 5: TESTAR PORTA 22 EM CADA IP
# ==========================

Write-Host ""
Write-Host "=== Testando porta 22 (SSH) em cada IP ==="
Write-Log "Iniciando teste da porta 22 em cada IP..."

$validIP = $null
foreach ($ip in $ips) {
    Write-Host "Testando IP $ip na porta 22..."
    Write-Log "Testando IP $ip na porta 22..."

    if (Test-SshPort -IpAddress $ip -Port 22) {
        $validIP = $ip
        Write-Log "Porta 22 respondeu no IP $ip"
        break
    }
    else {
        Write-Log "Porta 22 NAO respondeu no IP $ip" "WARN"
    }
}

if (-not $validIP) {
    Write-Host ""
    Write-Host "SSH não respondeu em nenhum IP disponível. Verifique o serviço ou firewall."
    Write-Log "SSH não respondeu em nenhum IP disponível." "ERROR"
}
else {
    Write-Host ""
    Write-Host "="
    Write-Host " INSTALAÇÃO E CONFIGURAÇAO CONCLUIDAS"
    Write-Host "="
    Write-Host ""
    Write-Host "Para conectar via SSH:"
    Write-Host " • Dominio: ssh DOMINIO\\usuario@$validIP"
    Write-Host " • Workgroup: ssh usuario@$validIP"
    Write-Host ""
    Write-Host "Exemplo:"
    Write-Host " ssh SAUDE\\joilson_admin@$validIP"
    Write-Log "Script concluido com sucesso. IP válido para SSH: $validIP"
}

Write-Host ""
Write-Host "Log detalhado salvo em: $logFile"
Write-Host ""
Read-Host "Pressione ENTER para sair"
