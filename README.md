

# Install_SSH
Script para Instalação ambígua do Servidor SSH pelo pacote offline e o pacote oficial.

#  Instalador Automático do OpenSSH para Windows

Este repositório fornece um instalador completo e automatizado do **OpenSSH Server + Client** para Windows, com suporte a:

- Instalação manual via pacote ZIP (prioridade máxima)
- Instalação online via Windows Capability
- Fallback automático via GitHub
- Execução remota via PowerShell
- Desinstalação completa do OpenSSH manual

Ideal para ambientes corporativos, máquinas offline, automação via scripts ou padronização de ambientes Windows.

---

# ⚡ Instalação Rápida (1 comando)

Abra o **PowerShell como Administrador** e execute:

```powershell
iwr -useb "https://raw.githubusercontent.com/jhoylsonn/Install_SSH/main/Install-SSH-Remote.ps1" | iex

Link Curto:
iwr -useb "https://tinyurl.com/install-ssh" | iex
