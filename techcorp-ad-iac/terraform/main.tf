# ---------------------------------------------------------------------------
# Datos: AMI Windows Server más reciente
# ---------------------------------------------------------------------------
data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.windows_ami_name_filter]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ---------------------------------------------------------------------------
# VPC y subred
# ---------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch  = true

  tags = {
    Name = "${var.project_name}-public"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id  = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Opciones DHCP: dominio y DNS = IP privada del DC01
# ---------------------------------------------------------------------------
resource "aws_vpc_dhcp_options" "ad" {
  domain_name         = var.domain_name
  domain_name_servers = [var.dc01_private_ip]

  tags = {
    Name = "${var.project_name}-dhcp-ad"
  }
}

resource "aws_vpc_dhcp_options_association" "main" {
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.ad.id
}

# ---------------------------------------------------------------------------
# Security Group: RDP + puertos Active Directory
# ---------------------------------------------------------------------------
resource "aws_security_group" "ad" {
  name        = "${var.project_name}-sg-ad"
  description = "RDP y puertos Active Directory"
  vpc_id      = aws_vpc.main.id

  # RDP
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.allowed_rdp_cidr]
  }

  # DNS
  ingress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Kerberos
  ingress {
    description = "Kerberos TCP"
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "Kerberos UDP"
    from_port   = 88
    to_port     = 88
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # RPC
  ingress {
    description = "RPC Endpoint Mapper"
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # LDAP
  ingress {
    description = "LDAP"
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # SMB
  ingress {
    description = "SMB"
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # LDAPS
  ingress {
    description = "LDAP SSL"
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Global Catalog
  ingress {
    description = "Global Catalog"
    from_port   = 3268
    to_port     = 3268
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "Global Catalog SSL"
    from_port   = 3269
    to_port     = 3269
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # RPC dinámico
  ingress {
    description = "RPC dinámico"
    from_port   = 49152
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-ad"
  }
}

# ---------------------------------------------------------------------------
# DC01: Controlador de dominio
# ---------------------------------------------------------------------------
resource "aws_instance" "dc01" {
  ami                    = data.aws_ami.windows.id
  instance_type           = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  private_ip              = var.dc01_private_ip
  vpc_security_group_ids  = [aws_security_group.ad.id]

  root_block_device {
    volume_size = var.dc01_volume_size
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/userdata_dc01.ps1.tpl", {
    domain_name         = var.domain_name
    safe_mode_password  = var.safe_mode_password
    domain_admin_pass   = var.domain_admin_password
    script_02_content   = base64encode(file("${path.module}/../scripts/dc01/02-admin-user.ps1"))
    script_03_content   = base64encode(file("${path.module}/../scripts/dc01/03-CrearEstructuraAD.ps1"))
    script_04_content   = base64encode(file("${path.module}/../scripts/dc01/04-RecursosCompartidos.ps1"))
    script_05_content   = base64encode(file("${path.module}/../scripts/dc01/05-GPO.ps1"))
    csv_content         = base64encode(file("${path.module}/../scripts/dc01/techcorp_usuarios.csv"))
  })

  tags = {
    Name = "DC01"
  }
}

# ---------------------------------------------------------------------------
# Cliente: unión al dominio (user_data tras disponibilidad del DC)
# ---------------------------------------------------------------------------
resource "aws_instance" "cliente" {
  ami                    = data.aws_ami.windows.id
  instance_type           = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ad.id]

  root_block_device {
    volume_size = var.cliente_volume_size
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/userdata_cliente.ps1.tpl", {
    domain_name            = var.domain_name
    dc01_private_ip        = var.dc01_private_ip
    domain_admin_user      = "admin.dominio"
    domain_admin_password  = var.domain_admin_password
    join_script_content    = base64encode(file("${path.module}/../scripts/cliente/01-join-domain.ps1"))
  })

  depends_on = [aws_instance.dc01]
}
