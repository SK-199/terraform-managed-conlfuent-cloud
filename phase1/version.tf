terraform {
  required_version = ">= 1.6.0"

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "2.86.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.17.0"
    }
  }
}
