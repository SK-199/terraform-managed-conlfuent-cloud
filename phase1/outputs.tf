output "environment_id" {
  description = "Confluent Cloud environment ID"
  value       = confluent_environment.this.id
}

output "environment_name" {
  description = "Confluent Cloud environment name"
  value       = confluent_environment.this.display_name
}

output "kafka_cluster_id" {
  description = "Enterprise Kafka cluster ID"
  value       = module.kafka_cluster.id
}

output "kafka_cluster_name" {
  description = "Enterprise Kafka cluster name"
  value       = module.kafka_cluster.display_name
}

output "kafka_rest_endpoint" {
  description = "Kafka REST endpoint"
  value       = module.kafka_cluster.rest_endpoint
}

output "kafka_bootstrap_endpoint" {
  description = "Kafka bootstrap endpoint"
  value       = module.kafka_cluster.bootstrap_endpoint
}
