# 02-admin-user.ps1
# Crear usuario administrador del dominio (admin.dominio) y añadirlo a Domain Admins.
# La contraseña se toma de $env:DOMAIN_ADMIN_PASSWORD (configurado por user_data o Run-AfterReboot).

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$password = if ($env:DOMAIN_ADMIN_PASSWORD) { $env:DOMAIN_ADMIN_PASSWORD } else { "Admin2025!" }
$pass = ConvertTo-SecureString $password -AsPlainText -Force

New-ADUser -Name "admin.dominio" -SamAccountName "admin.dominio" `
    -DisplayName "Administrador del dominio" `
    -UserPrincipalName "admin.dominio@$((Get-ADDomain).DNSRoot)" `
    -AccountPassword $pass -Enabled $true -PasswordNeverExpires $true

Add-ADGroupMember -Identity "Domain Admins" -Members "admin.dominio"
Write-Host "Usuario admin.dominio creado y añadido a Domain Admins." -ForegroundColor Green
