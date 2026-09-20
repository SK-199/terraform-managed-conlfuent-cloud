variable "vpc_cidr" {
  description = "CIDR block for the AWS VPC"
  type        = string
}

variable "availability_zone_ids" {
  description = "AWS Availability Zone IDs"
  type        = list(string)
}

variable "subnet_cidrs" {
  description = "Private subnet CIDRs mapped to the Availability Zones"
  type        = list(string)

  validation {
    condition     = length(var.subnet_cidrs) == length(var.availability_zone_ids)
    error_message = "The number of subnet CIDRs must match the number of Availability Zone IDs."
  }
}
