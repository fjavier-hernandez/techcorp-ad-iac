# 01-join-domain.ps1
# Unir este equipo al dominio. En el DC01 debe estar habilitado RDP para Domain Users.
# Uso desde user_data: -DomainName "techcorp.local" -Credential (PSCredential)
# Uso manual: .\01-join-domain.ps1 -DomainName "techcorp.local" -Credential (Get-Credential "techcorp\admin.dominio")

param(
    [Parameter(Mandatory = $true)]
    [string] $DomainName,
    [Parameter(Mandatory = $false)]
    [PSCredential] $Credential
)

$ErrorActionPreference = "Stop"

if (-not $Credential) {
    $Credential = Get-Credential -Message "Credenciales de administrador del dominio para unir al dominio"
}

Add-Computer -DomainName $DomainName -Credential $Credential -Restart
