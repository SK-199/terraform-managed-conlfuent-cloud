# Networking resources are implemented in:
# modules/aws-pni/
#
# This file is intentionally kept for future
# root-level networking resources such as:
# - additional Confluent networking
# - IP filters/groups
# - network linking
# - additional access points

#phase2-start
module "aws_networking" {
  source = "./modules/aws-networking"

  vpc_cidr = var.aws_vpc_cidr

  availability_zone_ids = [
    "ap-south-1a",
    "ap-south-1b",
    "ap-south-1c"
  ]

  subnet_cidrs = [
    "10.50.0.0/26",
    "10.50.0.64/26",
    "10.50.0.128/26"
  ]
}
#phase2-end
