# 04-RecursosCompartidos.ps1
# Carpetas compartidas TechCorp_Users y TechCorp_Datos, carpetas personales (unidad X:).
# Requiere: ejecutar en el DC como Administrador (después de 03-CrearEstructuraAD.ps1).

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

$dominio = (Get-ADDomain).NetBIOSName
$servidor = $env:COMPUTERNAME
$baseOU = "OU=TechCorp,$((Get-ADDomain).DistinguishedName)"

# 1. Estructura de carpetas
New-Item -Path "C:\TechCorp_Users" -ItemType Directory -Force
New-Item -Path "C:\TechCorp_Datos" -ItemType Directory -Force
@("Gerencia", "IT", "Administracion", "Comercial", "RRHH") | ForEach-Object {
    New-Item -Path "C:\TechCorp_Datos\$_" -ItemType Directory -Force
}

# 2. Compartir carpetas
New-SmbShare -Name "TechCorp_Users" -Path "C:\TechCorp_Users" -ChangeAccess "Domain Users" -Force
New-SmbShare -Name "TechCorp_Datos" -Path "C:\TechCorp_Datos" -ReadAccess "Domain Users" -Force

# 3. Carpetas personales y permisos NTFS por usuario
$usuarios = Get-ADUser -Filter * -SearchBase $baseOU -SearchScope Subtree | Where-Object { $_.Enabled }
foreach ($u in $usuarios) {
    $userPath = "C:\TechCorp_Users\$($u.SamAccountName)"
    New-Item -Path $userPath -ItemType Directory -Force
    $acl = Get-Acl $userPath
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "$dominio\$($u.SamAccountName)", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
    )
    $acl.AddAccessRule($rule)
    Set-Acl $userPath $acl
    Set-ADUser -Identity $u.SamAccountName -HomeDrive "X:" -HomeDirectory "\\$servidor\TechCorp_Users\$($u.SamAccountName)"
}
Write-Host "Carpetas personales configuradas para $($usuarios.Count) usuarios" -ForegroundColor Green
