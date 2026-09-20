output "vpc_id" {
  description = "AWS VPC ID used for PNI"
  value       = aws_vpc.pni.id
}

output "subnet_ids" {
  description = "AWS subnet IDs used for PNI"
  value       = aws_subnet.pni[*].id
}

output "security_group_id" {
  description = "Security group used by PNI ENIs"
  value       = aws_security_group.pni.id
}

output "gateway_id" {
  description = "Confluent PNI gateway ID"
  value       = confluent_gateway.pni.id
}

output "access_point_id" {
  description = "Confluent PNI access point ID"
  value       = confluent_access_point.pni.id
}

output "network_interface_ids" {
  description = "AWS ENIs used by PNI"
  value       = aws_network_interface.pni[*].id
}
