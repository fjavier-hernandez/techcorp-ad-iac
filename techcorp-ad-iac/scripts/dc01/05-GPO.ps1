# 05-GPO.ps1
# GPO: directiva de contraseñas (vigencia, historial, longitud) y bloqueo de cuenta.
# Configuración recomendada (reto): vigencia 90 días, historial 5, longitud mín. 4, bloqueo 4 intentos.
# La GPO del dominio puede afinarse en gpmc.msc (Default Domain Policy). Aquí se habilita RDP para Domain Users.

$ErrorActionPreference = "Stop"

# Habilitar RDP para Domain Users en DC01 (permite conexión con usuarios del dominio)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "Domain Users" -ErrorAction SilentlyContinue
Write-Host "RDP habilitado para Domain Users en DC01" -ForegroundColor Green

# GPO de contraseñas y bloqueo: en un DC la forma estándar es editar Default Domain Policy en gpmc.msc:
# - Configuración del equipo > Directivas > Configuración de Windows > Configuración de seguridad > Directivas de cuenta
# - Directivas de contraseña: vigencia máx. 90 días, historial 5, longitud mín. 4, sin complejidad.
# - Directiva de bloqueo: 4 intentos, restablecer contador 10 min, duración bloqueo 0.
# Forzar actualización en clientes: gpupdate /force
Write-Host "GPO de contraseñas y bloqueo: configurar en gpmc.msc (Default Domain Policy) si se requiere automatización completa." -ForegroundColor Yellow
