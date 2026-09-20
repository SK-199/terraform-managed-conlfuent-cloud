resource "aws_vpc" "pni" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "confluent-pni-vpc"
  }
}

resource "aws_subnet" "pni" {
  count = length(var.availability_zone_ids)

  vpc_id = aws_vpc.pni.id

  cidr_block = cidrsubnet(
    var.aws_vpc_cidr,
    2,
    count.index
  )

  availability_zone_id = var.availability_zone_ids[count.index]

  tags = {
    Name = "confluent-pni-subnet-${count.index + 1}"
  }
}

resource "aws_security_group" "pni" {
  name        = "confluent-pni"
  description = "Security group for Confluent PNI ENIs"
  vpc_id      = aws_vpc.pni.id

  ingress {
    description = "Kafka broker access"
    protocol    = "tcp"
    from_port   = 9092
    to_port     = 9092
    cidr_blocks = [var.aws_vpc_cidr]
  }

  ingress {
    description = "Kafka REST API access"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.aws_vpc_cidr]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "confluent-pni"
  }
}


resource "confluent_gateway" "pni" {
  display_name = "aws-pni-gateway"

  environment {
    id = var.environment_id
  }

  aws_private_network_interface_gateway {
    region = var.aws_region
    zones  = var.availability_zone_ids
  }
}



resource "aws_network_interface" "pni" {
  count = length(var.availability_zone_ids) * var.eni_count_per_subnet

  subnet_id = aws_subnet.pni[
    floor(count.index / var.eni_count_per_subnet)
  ].id

  security_groups = [
    aws_security_group.pni.id
  ]

  description = "Confluent PNI ENI ${count.index + 1}"

  tags = {
    Name = "confluent-pni-eni-${count.index + 1}"
  }

  depends_on = [
    confluent_gateway.pni
  ]
}



resource "aws_network_interface_permission" "pni" {
  count = length(aws_network_interface.pni)

  network_interface_id = aws_network_interface.pni[count.index].id

  permission = "INSTANCE-ATTACH"

  aws_account_id = confluent_gateway.pni.aws_private_network_interface_gateway[0].account
}


data "aws_caller_identity" "current" {}

resource "confluent_access_point" "pni" {
  display_name = "aws-pni-access-point"

  environment {
    id = var.environment_id
  }

  gateway {
    id = confluent_gateway.pni.id
  }

  aws_private_network_interface {
    network_interfaces = aws_network_interface.pni[*].id
    account            = data.aws_caller_identity.current.account_id
  }

  depends_on = [
    aws_network_interface_permission.pni
  ]
}



