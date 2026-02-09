variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
}

variable "enable_dns_support" {
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  type        = bool
  default     = true
}

variable "subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
    type              = string  # "public" or "private" or "isolated"
    tier              = string
    tags              = optional(map(string), {})
  }))
  description = "Subnets definition"
}

variable "nat_gateways" {
  type = map(object({
    subnet_key = string
    tags       = map(string)
  }))
    description = "Map of NAT gateways to create"
}


variable "tags" {
  type        = map(string)
  description = "Common tags"
}
