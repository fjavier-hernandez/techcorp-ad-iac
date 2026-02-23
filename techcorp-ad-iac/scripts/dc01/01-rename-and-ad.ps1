# 01-rename-and-ad.ps1
# Nombre del equipo, instalación del rol AD DS y promoción a controlador de dominio.
# Uso: se ejecuta desde user_data de Terraform; variables desde template.
# Si se ejecuta a mano: $env:DOMAIN_NAME = "techcorp.local"; $env:SAFE_MODE_PASSWORD = "..."

$ErrorActionPreference = "Stop"
$domainName = if ($env:DOMAIN_NAME) { $env:DOMAIN_NAME } else { "techcorp.local" }
$safeModePassword = if ($env:SAFE_MODE_PASSWORD) { $env:SAFE_MODE_PASSWORD } else { "TechCorp2025!" }

Rename-Computer -NewName "DC01" -Force

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

$secureSafeMode = ConvertTo-SecureString $safeModePassword -AsPlainText -Force
Import-Module ADDSDeployment
Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetbiosName "TECHCORP" `
    -DomainMode WinThreshold `
    -ForestMode WinThreshold `
    -InstallDns:$true `
    -CreateDnsDelegation:$false `
    -SafeModeAdministratorPassword $secureSafeMode `
    -Force
