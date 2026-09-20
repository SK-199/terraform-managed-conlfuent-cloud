resource "confluent_access_point" "pni" {
  display_name = "dev-pni-access-point"

  environment {
    id = confluent_environment.this.id
  }

  gateway {
    id = confluent_gateway.pni.id
  }

  aws_private_network_interface {
    network_interfaces = aws_network_interface.pni[*].id
    account            = var.aws_account_id
  }
}
