variable "environment_id" {
  description = "Confluent Cloud environment ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_vpc_cidr" {
  description = "CIDR block for the AWS VPC"
  type        = string
}

variable "availability_zone_ids" {
  description = "Three AWS Availability Zone IDs"
  type        = list(string)
}

variable "eni_count_per_subnet" {
  description = "Number of PNI ENIs per subnet"
  type        = number
}
