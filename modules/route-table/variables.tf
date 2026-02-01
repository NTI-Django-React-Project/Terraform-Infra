variable "region" {
  description = "AWS region where the Route Table will be created"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "vpc_id" {
  description = "The VPC ID where Route Table will be created"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID format (e.g., vpc-12345678)."
  }
}

variable "route_tables" {
  description = "Map of route tables to create"
  type = map(object({
    routes = optional(list(object({
      cidr_block                 = optional(string)
      ipv6_cidr_block            = optional(string)
      destination_prefix_list_id = optional(string)
      gateway_id                 = optional(string)
      nat_gateway_id             = optional(string)
      network_interface_id       = optional(string)
      transit_gateway_id         = optional(string)
      vpc_peering_connection_id  = optional(string)
      egress_only_gateway_id     = optional(string)
      carrier_gateway_id         = optional(string)
      local_gateway_id           = optional(string)
      vpc_endpoint_id            = optional(string)
    })), [])
    tags = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Common tags to apply to all route tables"
  type        = map(string)
  default     = {}
}
