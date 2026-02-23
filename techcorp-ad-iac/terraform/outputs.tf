output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "dc01_public_ip" {
  description = "IP pública del DC01 (conectar por RDP)"
  value       = aws_instance.dc01.public_ip
}

output "dc01_private_ip" {
  description = "IP privada del DC01 (DNS en opciones DHCP)"
  value       = aws_instance.dc01.private_ip
}

output "cliente_public_ip" {
  description = "IP pública del Cliente (conectar por RDP)"
  value       = aws_instance.cliente.public_ip
}

output "cliente_private_ip" {
  description = "IP privada del Cliente"
  value       = aws_instance.cliente.private_ip
}

output "domain_name" {
  description = "Nombre del dominio Active Directory"
  value       = var.domain_name
}

output "rdp_dc01" {
  description = "Instrucción para conectar por RDP al DC01"
  value       = "RDP a ${aws_instance.dc01.public_ip} con usuario Administrator (contraseña: obtener con clave .pem en consola EC2)"
}

output "rdp_cliente" {
  description = "Instrucción para conectar por RDP al Cliente"
  value       = "RDP a ${aws_instance.cliente.public_ip} (tras unión al dominio: usuario DOMINIO\\usuario)"
}
