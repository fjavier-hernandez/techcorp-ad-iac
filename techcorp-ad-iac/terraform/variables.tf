variable "aws_region" {
  description = "Región AWS donde desplegar (ej: eu-west-1)"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Nombre del proyecto para recursos"
  type        = string
  default     = "techcorp-ad"
}

variable "domain_name" {
  description = "Nombre del dominio Active Directory (ej: techcorp.local)"
  type        = string
  default     = "techcorp.local"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR de la subred pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "dc01_private_ip" {
  description = "IP privada fija del DC01 (debe estar dentro de public_subnet_cidr)"
  type        = string
  default     = "10.0.1.10"
}

variable "instance_type" {
  description = "Tipo de instancia EC2 (recomendado t3.large para Windows Server)"
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "Nombre del par de claves SSH existente en AWS para RDP (obtener contraseña)"
  type        = string
}

variable "allowed_rdp_cidr" {
  description = "CIDR desde el que se permite RDP (ej: tu IP o 0.0.0.0/0 para pruebas)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "dc01_volume_size" {
  description = "Tamaño del volumen raíz del DC01 (GB)"
  type        = number
  default     = 40
}

variable "cliente_volume_size" {
  description = "Tamaño del volumen raíz del Cliente (GB)"
  type        = number
  default     = 40
}

variable "safe_mode_password" {
  description = "Contraseña para el modo seguro (DSRM) del controlador de dominio"
  type        = string
  sensitive   = true
}

variable "domain_admin_password" {
  description = "Contraseña del usuario administrador del dominio (admin.dominio)"
  type        = string
  sensitive   = true
}

variable "windows_ami_name_filter" {
  description = "Filtro del nombre de la AMI Windows Server (ej: Windows_Server-2025)"
  type        = string
  default     = "Windows_Server-2025-English-Full-Base-*"
}
