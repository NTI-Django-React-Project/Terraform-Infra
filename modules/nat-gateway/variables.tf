variable "region" {
  description = "AWS region where the NAT Gateway will be created"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "vpc_id" {
  description = "The VPC ID where NAT Gateway will be created"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID format (e.g., vpc-12345678)."
  }
}

variable "connectivity_type" {
  description = "Connectivity type for the NAT Gateway (public or private)"
  type        = string
  default     = "public"
  validation {
    condition     = contains(["public", "private"], var.connectivity_type)
    error_message = "Connectivity type must be either 'public' or 'private'."
  }
}

variable "nat_gateways" {
  description = "Map of NAT Gateways to create"
  type = map(object({
    subnet_id = string
    tags      = optional(map(string), {})
  }))
  validation {
    condition = alltrue([
      for k, v in var.nat_gateways : can(regex("^subnet-[a-z0-9]+$", v.subnet_id))
    ])
    error_message = "All subnet IDs must be valid AWS subnet ID format (e.g., subnet-12345678)."
  }
}

variable "tags" {
  description = "Common tags to apply to all NAT Gateway resources"
  type        = map(string)
  default     = {}
}
