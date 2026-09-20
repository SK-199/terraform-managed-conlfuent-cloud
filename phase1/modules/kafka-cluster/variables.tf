variable "environment_id" {
  description = "Confluent Cloud environment ID"
  type        = string
}

variable "display_name" {
  description = "Kafka cluster display name"
  type        = string
}

variable "availability" {
  description = "Enterprise cluster availability"
  type        = string
}

variable "cloud" {
  description = "Cloud provider"
  type        = string

  default = "AWS"
}

variable "region" {
  description = "Cloud region"
  type        = string
}

variable "max_ecku" {
  description = "Maximum eCKU capacity for the Enterprise cluster"
  type        = number

  validation {
    condition     = var.max_ecku >= 1
    error_message = "max_ecku must be at least 1."
  }
}
