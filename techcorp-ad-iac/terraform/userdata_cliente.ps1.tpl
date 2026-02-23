<powershell>
# User data Cliente: esperar al DC y unir al dominio
$domainName = "${domain_name}"
$dc01Ip = "${dc01_private_ip}"
$adminUser = "${domain_admin_user}"
$adminPass = "${domain_admin_password}"
$joinScriptB64 = "${join_script_content}"

# Esperar a que el DC responda en 389 (LDAP)
$maxAttempts = 60
$attempt = 0
do {
  $attempt++
  try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect($dc01Ip, 389)
    $tcp.Close()
    break
  } catch {}
  Start-Sleep -Seconds 10
} while ($attempt -lt $maxAttempts)

if ($attempt -ge $maxAttempts) { exit 1 }

# Escribir y ejecutar script de unión al dominio (usa credenciales)
New-Item -Path C:\Scripts -ItemType Directory -Force
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($joinScriptB64)) | Set-Content -Path C:\Scripts\01-join-domain.ps1 -Encoding UTF8

$securePass = ConvertTo-SecureString $adminPass -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("$domainName\$adminUser", $securePass)
& C:\Scripts\01-join-domain.ps1 -DomainName $domainName -Credential $cred
</powershell>
