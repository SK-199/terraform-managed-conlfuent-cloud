resource "confluent_environment" "this" {
  display_name = var.environment_name

  stream_governance {
    package = var.stream_governance_package
  }
}

module "kafka_cluster" {
  source = "./modules/kafka-cluster"

  environment_id = confluent_environment.this.id

  display_name = var.kafka_cluster_name
  availability = var.kafka_availability
  cloud        = "AWS"
  region       = var.aws_region
  max_ecku     = var.kafka_max_ecku

  depends_on = [
    confluent_environment.this
  ]
}
