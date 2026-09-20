variable "environment_name" {
  description = "Confluent Cloud environment name"
  type        = string
}

variable "stream_governance_package" {
  description = "Confluent Stream Governance package"
  type        = string

  validation {
    condition     = contains(["ESSENTIALS", "ADVANCED"], var.stream_governance_package)
    error_message = "stream_governance_package must be ESSENTIALS or ADVANCED."
  }
}

variable "kafka_cluster_name" {
  description = "Kafka cluster display name"
  type        = string
}

variable "kafka_availability" {
  description = "Enterprise Kafka cluster availability"
  type        = string

  validation {
    condition     = contains(["LOW", "HIGH"], var.kafka_availability)
    error_message = "kafka_availability must be LOW or HIGH."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string

  default = "ap-south-1"
}

variable "kafka_max_ecku" {
  description = "Maximum eCKU capacity for the development Enterprise cluster"
  type        = number

  default = 1

  validation {
    condition     = var.kafka_max_ecku >= 1
    error_message = "kafka_max_ecku must be at least 1."
  }
}
