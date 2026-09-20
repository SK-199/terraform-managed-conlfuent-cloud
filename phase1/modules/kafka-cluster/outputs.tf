output "id" {
  description = "Kafka cluster ID"
  value       = confluent_kafka_cluster.this.id
}

output "display_name" {
  description = "Kafka cluster display name"
  value       = confluent_kafka_cluster.this.display_name
}

output "rest_endpoint" {
  description = "Kafka REST endpoint"
  value       = confluent_kafka_cluster.this.rest_endpoint
}

output "bootstrap_endpoint" {
  description = "Kafka bootstrap endpoint"
  value       = confluent_kafka_cluster.this.bootstrap_endpoint
}

output "rbac_crn" {
  description = "Kafka cluster RBAC CRN"
  value       = confluent_kafka_cluster.this.rbac_crn
}
