<powershell>
# User data DC01: preparar scripts, ejecutar 01 (nombre + AD + DC) y programar 02-05 tras reinicio
$ErrorActionPreference = "Stop"
$domainName = "${domain_name}"
$safeModePassword = "${safe_mode_password}"
$domainAdminPass = "${domain_admin_pass}"

# Crear C:\Scripts y escribir scripts 02-05 y CSV (decodificados)
New-Item -Path C:\Scripts -ItemType Directory -Force
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("${script_02_content}")) | Set-Content -Path C:\Scripts\02-admin-user.ps1 -Encoding UTF8
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("${script_03_content}")) | Set-Content -Path C:\Scripts\03-CrearEstructuraAD.ps1 -Encoding UTF8
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("${script_04_content}")) | Set-Content -Path C:\Scripts\04-RecursosCompartidos.ps1 -Encoding UTF8
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("${script_05_content}")) | Set-Content -Path C:\Scripts\05-GPO.ps1 -Encoding UTF8
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("${csv_content}")) | Set-Content -Path C:\Scripts\techcorp_usuarios.csv -Encoding UTF8

# Script que se ejecutará tras el reinicio (02 -> 05)
$runAfterReboot = @"
`$env:DOMAIN_ADMIN_PASSWORD = '$domainAdminPass'
Start-Sleep -Seconds 180
Set-Location C:\Scripts
& .\02-admin-user.ps1
& .\03-CrearEstructuraAD.ps1
& .\04-RecursosCompartidos.ps1
& .\05-GPO.ps1
"@
$runAfterReboot | Set-Content -Path C:\Scripts\Run-AfterReboot.ps1 -Encoding UTF8

# Programar tarea al inicio para ejecutar 02-05
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\Run-AfterReboot.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup -User "SYSTEM"
Register-ScheduledTask -TaskName "TechCorp-PostAD" -Action $action -Trigger $trigger -RunLevel Highest -Force

# 01: Nombre del equipo
Rename-Computer -NewName "DC01" -Force

# Instalar rol AD DS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promover a controlador de dominio (reinicia al final)
$secureSafeMode = ConvertTo-SecureString $safeModePassword -AsPlainText -Force
Import-Module ADDSDeployment
Install-ADDSForest -DomainName $domainName -DomainNetbiosName "TECHCORP" -DomainMode WinThreshold -ForestMode WinThreshold -InstallDns:$true -SafeModeAdministratorPassword $secureSafeMode -Force
</powershell>
