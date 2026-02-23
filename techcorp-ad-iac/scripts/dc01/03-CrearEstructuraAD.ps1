# 03-CrearEstructuraAD.ps1
# OUs TechCorp por departamento, 20 usuarios desde CSV y grupos por departamento.
# Requiere: ejecutar como Administrador tras instalar AD (después de 02-admin-user.ps1).

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$domain = (Get-ADDomain).DNSRoot
$domainDN = (Get-ADDomain).DistinguishedName
$baseOU = "OU=TechCorp,$domainDN"
$csvPath = "C:\Scripts\techcorp_usuarios.csv"

# 1. Crear OU raíz y sub-OUs por departamento
$departamentos = @("Gerencia", "IT", "Administracion", "Comercial", "RRHH")
New-ADOrganizationalUnit -Name "TechCorp" -Path $domainDN -ErrorAction SilentlyContinue
foreach ($dept in $departamentos) {
    New-ADOrganizationalUnit -Name $dept -Path $baseOU -ErrorAction SilentlyContinue
}

# 2. Crear usuarios desde CSV
$usuarios = Import-Csv -Path $csvPath -Encoding UTF8
foreach ($u in $usuarios) {
    $ouPath = "OU=$($u.OU),$baseOU"
    $pass = ConvertTo-SecureString $u.Contraseña -AsPlainText -Force
    try {
        New-ADUser -Name "$($u.Nombre) $($u.Apellido)" -GivenName $u.Nombre -Surname $u.Apellido `
            -SamAccountName $u.InicioSesion -UserPrincipalName "$($u.InicioSesion)@$domain" `
            -Path $ouPath -AccountPassword $pass -PasswordNeverExpires $true -Enabled $true -Description $u.Posicion
        Write-Host "OK: $($u.InicioSesion)" -ForegroundColor Green
    } catch { Write-Host "Error $($u.InicioSesion): $_" -ForegroundColor Red }
}

# 3. Crear grupos por departamento
$grupos = @("Gerencia_Usuarios", "IT_Usuarios", "Administracion_Usuarios", "Comercial_Usuarios", "RRHH_Usuarios")
foreach ($g in $grupos) {
    New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path $baseOU -ErrorAction SilentlyContinue
}

# 4. Añadir usuarios a sus grupos
$mapOU = @{
    Gerencia       = "Gerencia_Usuarios"
    IT             = "IT_Usuarios"
    Administracion  = "Administracion_Usuarios"
    Comercial       = "Comercial_Usuarios"
    RRHH           = "RRHH_Usuarios"
}
foreach ($u in $usuarios) {
    $grupo = $mapOU[$u.OU]
    if ($grupo) { Add-ADGroupMember -Identity $grupo -Members $u.InicioSesion -ErrorAction SilentlyContinue }
}

Write-Host "`nEstructura creada. Usuarios: $($usuarios.Count)" -ForegroundColor Cyan
