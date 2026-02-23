# techcorp-ad-iac

Despliegue con Terraform en AWS de una arquitectura mínima para Active Directory (TechCorp). Despliegue automatizado de un controlador de dominio (DC01), un cliente Windows unido al dominio, OUs, 20 usuarios desde CSV, grupos, recursos compartidos y GPO, con un único `terraform apply`.

## Requisitos

- **Cuenta AWS** (educativa o con créditos) y **AWS CLI** configurado (`aws sts get-caller-identity`).
- **Terraform** ≥ 1.0 (`terraform version`).
- **Par de claves** en EC2 para obtener la contraseña de RDP de las instancias Windows.

## Estructura del proyecto

```
techcorp-ad-iac/
├── terraform/
│   ├── provider.tf          # Proveedor AWS y versión Terraform
│   ├── main.tf               # VPC, subred, SG, DHCP, EC2 DC01 y Cliente
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── userdata_dc01.ps1.tpl # User data DC01 (01 + programación 02-05)
│   └── userdata_cliente.ps1.tpl
├── scripts/
│   ├── dc01/                 # Scripts ejecutados en DC01 (orden 01 → 05)
│   │   ├── 01-rename-and-ad.ps1
│   │   ├── 02-admin-user.ps1
│   │   ├── 03-CrearEstructuraAD.ps1
│   │   ├── 04-RecursosCompartidos.ps1
│   │   ├── 05-GPO.ps1
│   │   └── techcorp_usuarios.csv
│   └── cliente/
│       └── 01-join-domain.ps1
└── README.md
```

## Variables principales

| Variable | Descripción | Por defecto |
|----------|-------------|-------------|
| `aws_region` | Región AWS | `eu-west-1` |
| `domain_name` | Dominio AD | `techcorp.local` |
| `key_name` | Par de claves EC2 | **(obligatorio)** |
| `allowed_rdp_cidr` | CIDR permitido para RDP | `0.0.0.0/0` |
| `safe_mode_password` | Contraseña DSRM | **(sensible)** |
| `domain_admin_password` | Contraseña admin.dominio | **(sensible)** |

Copiar `terraform/terraform.tfvars.example` a `terraform/terraform.tfvars` y rellenar `key_name`, `safe_mode_password` y `domain_admin_password`. No subir `terraform.tfvars` si contiene contraseñas.

## Pasos para ejecutar

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Tras el apply, la infraestructura se crea y:

1. **DC01**: en el primer arranque se ejecuta el equivalente a `01-rename-and-ad.ps1` (nombre DC01, instalación AD DS, promoción a DC, reinicio). Tras el reinicio, una tarea programada ejecuta en orden `02-admin-user.ps1`, `03-CrearEstructuraAD.ps1`, `04-RecursosCompartidos.ps1` y `05-GPO.ps1`.
2. **Cliente**: el user_data espera a que el DC responda (LDAP) y luego ejecuta `01-join-domain.ps1` con las credenciales de `admin.dominio`, uniendo el equipo al dominio y reiniciando.

## Mecanismo de ejecución de scripts

- **DC01 y Cliente**: los scripts se ejecutan mediante **user_data** de las instancias EC2. Los scripts de `scripts/dc01` y `scripts/cliente` se inyectan (codificados) en las plantillas `userdata_dc01.ps1.tpl` y `userdata_cliente.ps1.tpl`.
- **Orden en DC01**: 01 (nombre + AD + DC + reinicio) → tras reinicio: 02 → 03 → 04 → 05.

## Acceso por RDP

```bash
terraform output
```

- **DC01**: IP pública en `dc01_public_ip`. Usuario: `Administrator` (contraseña: obtener con la clave `.pem` en EC2 → Conectar → Obtener contraseña). Tras los scripts, también `TECHCORP\admin.dominio` y usuarios del CSV.
- **Cliente**: IP pública en `cliente_public_ip`. Tras la unión al dominio, iniciar sesión con `TECHCORP\<usuario>` (por ejemplo `ana.garcia` con contraseña del CSV).

## Destruir recursos

```bash
cd terraform
terraform destroy
```

Confirma con `yes` para eliminar VPC, instancias y recursos asociados.

## Verificación (Fase 2 del reto)

1. **DC01**: comprobar que es controlador de dominio (`Get-ADDomain`, `Get-ADDomainController`), OUs (Gerencia, IT, Administración, Comercial, RRHH), 20 usuarios y grupos.
2. **Recursos compartidos**: `TechCorp_Users`, `TechCorp_Datos` y carpetas personales (unidad X:).
3. **Cliente**: `ipconfig /all` (sufijo DNS y servidor DNS = IP del DC01), comprobar unión al dominio e inicio de sesión con un usuario del dominio.

## Referencias

- Reto práctico: Active Directory en AWS (TechCorp).
- Prácticas: Windows Server en AWS, Active Directory en AWS, Reto grupal Active Directory.
