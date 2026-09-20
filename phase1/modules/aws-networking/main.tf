resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "confluent-cloud-dev-vpc"
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zone_ids)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.availability_zone_ids[count.index]
  cidr_block        = var.subnet_cidrs[count.index]

  tags = {
    Name = "confluent-cloud-dev-private-${count.index + 1}"
  }
}
