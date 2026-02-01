variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC ID format (e.g., vpc-12345678)."
  }
}

variable "security_groups" {
  description = "Map of security groups to create with their rules"
  type = map(object({
    description = string
    ingress_rules = optional(list(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      cidr_blocks              = optional(list(string))
      ipv6_cidr_blocks         = optional(list(string))
      source_security_group_id = optional(string)
      description              = optional(string)
    })), [])
    egress_rules = optional(list(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      cidr_blocks              = optional(list(string))
      ipv6_cidr_blocks         = optional(list(string))
      source_security_group_id = optional(string)
      description              = optional(string)
    })), [])
    tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.security_groups : length(k) >= 1 && length(k) <= 255
    ])
    error_message = "Security group names must be between 1 and 255 characters."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.security_groups : [
        for rule in concat(
          lookup(v, "ingress_rules", []),
          lookup(v, "egress_rules", [])
        ) : contains(["-1", "tcp", "udp", "icmp", "icmpv6"], rule.protocol)
      ]
    ]))
    error_message = "Protocol must be one of: -1 (all), tcp, udp, icmp, icmpv6."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.security_groups : [
        for rule in concat(
          lookup(v, "ingress_rules", []),
          lookup(v, "egress_rules", [])
        ) : rule.from_port >= -1 && rule.from_port <= 65535 && 
            rule.to_port >= -1 && rule.to_port <= 65535
      ]
    ]))
    error_message = "Port numbers must be between -1 and 65535."
  }
}

variable "tags" {
  description = "Common tags to apply to all security groups"
  type        = map(string)
  default     = {}
}
