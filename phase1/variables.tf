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

variable "aws_vpc_cidr" {
  description = "CIDR block provided for the AWS VPC"
  type        = string
}

variable "aws_availability_zone_ids" {
  description = "AWS Availability Zone IDs provided for the private networking design"
  type        = list(string)

  validation {
    condition     = length(var.aws_availability_zone_ids) == 3
    error_message = "Exactly 3 Availability Zone IDs are required for this Phase 2 design."
  }
}

variable "pni_eni_count_per_subnet" {
  description = "Number of PNI ENIs to provision per subnet"
  type        = number

  validation {
    condition     = var.pni_eni_count_per_subnet >= 1
    error_message = "pni_eni_count_per_subnet must be at least 1."
  }
}

variable "confluent_aws_account_id" {
  description = "Confluent AWS account ID used for PNI ENI attachment permissions"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.confluent_aws_account_id))
    error_message = "confluent_aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "aws_account_id" {
  description = "AWS account ID that owns the PNI ENIs"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}
