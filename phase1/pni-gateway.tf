resource "confluent_gateway" "pni" {
  display_name = "dev-pni-gateway"

  environment {
    id = confluent_environment.this.id
  }

  aws_private_network_interface_gateway {
    region = var.aws_region

    zones = var.aws_availability_zone_ids
  }
}
