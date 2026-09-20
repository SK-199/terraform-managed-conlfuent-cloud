environment_name          = "dev"
stream_governance_package = "ESSENTIALS"

kafka_cluster_name = "dev-enterprise"
kafka_availability = "LOW"
kafka_max_ecku     = 1

aws_region   = "ap-south-1"
aws_vpc_cidr = "10.50.0.0/24"

aws_availability_zone_ids = [
  "aps1-az1",
  "aps1-az3",
  "aps1-az2"
]

pni_eni_count_per_subnet = 17
