variable "rules" {
  description = "Security group rules (ingress or egress)"
  type = map(object({
    type                     = string                # ingress | egress
    security_group_id        = string
    source_security_group_id = optional(string)
    cidr_blocks              = optional(list(string))
    from_port                = number
    to_port                  = number
    protocol                 = string
    description              = optional(string)
  }))
}
