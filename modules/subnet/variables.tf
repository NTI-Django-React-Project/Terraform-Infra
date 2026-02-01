variable "vpc_id" {
  description = "The VPC ID where subnets will be created"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID format (e.g., vpc-12345678)."
  }
}

variable "subnets" {
  description = "Map of subnets to create, key is the subnet name"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    tags              = optional(map(string), {})
  }))
  validation {
    condition = alltrue([
      for k, v in var.subnets : can(cidrhost(v.cidr_block, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR notation."
  }
  validation {
    condition = alltrue([
      for k, v in var.subnets : can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", v.availability_zone))
    ])
    error_message = "All availability zones must be valid AWS AZ format (e.g., us-east-1a)."
  }
}

variable "tags" {
  description = "Common tags to apply to all subnets"
  type        = map(string)
  default     = {}
}
