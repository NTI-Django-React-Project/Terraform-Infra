variable "region" {
  description = "AWS region where the Internet Gateway will be created"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "vpc_id" {
  description = "The VPC ID where Internet Gateway will be attached"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID format (e.g., vpc-12345678)."
  }
}

variable "tags" {
  description = "Tags to apply to the Internet Gateway"
  type        = map(string)
  default     = {}
  validation {
    condition     = can(var.tags["Name"])
    error_message = "Tags must include a 'Name' key."
  }
}
