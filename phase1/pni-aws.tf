resource "aws_security_group" "pni" {
  name        = "confluent-pni-dev"
  description = "Security group for Confluent PNI ENIs"
  vpc_id      = module.aws_networking.vpc_id

  # Block outbound traffic by default.
  # Add specific egress rules only when required.
  egress = []

  tags = {
    Name        = "confluent-pni-dev"
    Confluent   = "true"
    Environment = "dev"
  }
}

resource "aws_vpc_security_group_ingress_rule" "kafka" {
  security_group_id = aws_security_group.pni.id

  cidr_ipv4   = var.aws_vpc_cidr
  from_port   = 9092
  to_port     = 9092
  ip_protocol = "tcp"

  description = "Kafka client access"
}

resource "aws_vpc_security_group_ingress_rule" "rest" {
  security_group_id = aws_security_group.pni.id

  cidr_ipv4   = var.aws_vpc_cidr
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Kafka REST API access"
}

resource "aws_network_interface" "pni" {
  count = length(module.aws_networking.private_subnet_ids) * var.pni_eni_count_per_subnet

  subnet_id = module.aws_networking.private_subnet_ids[
    floor(count.index / var.pni_eni_count_per_subnet)
  ]

  security_groups = [
    aws_security_group.pni.id
  ]

  description = "Confluent PNI ENI ${count.index + 1}"

  tags = {
    Name        = "confluent-pni-${count.index + 1}"
    Confluent   = "true"
    Environment = "dev"
  }
}

resource "aws_network_interface_permission" "pni" {
  count = length(aws_network_interface.pni)

  network_interface_id = aws_network_interface.pni[count.index].id

  permission     = "INSTANCE-ATTACH"
  aws_account_id = var.confluent_aws_account_id
}
