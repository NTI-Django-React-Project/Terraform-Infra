variable "region" {
  description = "AWS region where the Route Table Association will be created"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "subnet_associations" {
  description = "Map of subnet associations to create"
  type = map(object({
    subnet_id      = string
    route_table_id = string
  }))
  default = {}
  validation {
    condition = alltrue([
      for k, v in var.subnet_associations : can(regex("^subnet-[a-z0-9]+$", v.subnet_id))
    ])
    error_message = "All subnet IDs must be valid AWS subnet ID format (e.g., subnet-12345678)."
  }
  validation {
    condition = alltrue([
      for k, v in var.subnet_associations : can(regex("^rtb-[a-z0-9]+$", v.route_table_id))
    ])
    error_message = "All route table IDs must be valid AWS route table ID format (e.g., rtb-12345678)."
  }
}

variable "gateway_associations" {
  description = "Map of gateway associations to create"
  type = map(object({
    gateway_id     = string
    route_table_id = string
  }))
  default = {}
  validation {
    condition = alltrue([
      for k, v in var.gateway_associations : can(regex("^(igw-|vpce-|vgw-)[a-z0-9]+$", v.gateway_id))
    ])
    error_message = "All gateway IDs must be valid AWS gateway ID format (e.g., igw-12345678)."
  }
  validation {
    condition = alltrue([
      for k, v in var.gateway_associations : can(regex("^rtb-[a-z0-9]+$", v.route_table_id))
    ])
    error_message = "All route table IDs must be valid AWS route table ID format (e.g., rtb-12345678)."
  }
}
