resource "confluent_kafka_cluster" "this" {
  display_name = var.display_name
  availability = var.availability
  cloud        = var.cloud
  region       = var.region

  enterprise {
    max_ecku = var.max_ecku
  }

  environment {
    id = var.environment_id
  }
}
