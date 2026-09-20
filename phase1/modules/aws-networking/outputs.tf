output "vpc_id" {
  description = "ID of the AWS VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the AWS VPC"
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDRs of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}
