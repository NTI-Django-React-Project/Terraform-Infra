terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = each.key
  description = each.value.description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

# Ingress rules
resource "aws_security_group_rule" "ingress" {
  for_each = {
    for rule in local.ingress_rules : "${rule.sg_name}-ingress-${rule.rule_index}" => rule
  }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks  = lookup(each.value, "ipv6_cidr_blocks", null)
  security_group_id = aws_security_group.this[each.value.sg_name].id
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  description       = lookup(each.value, "description", null)
}

# Egress rules
resource "aws_security_group_rule" "egress" {
  for_each = {
    for rule in local.egress_rules : "${rule.sg_name}-egress-${rule.rule_index}" => rule
  }

  type              = "egress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks  = lookup(each.value, "ipv6_cidr_blocks", null)
  security_group_id = aws_security_group.this[each.value.sg_name].id
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  description       = lookup(each.value, "description", null)
}

locals {
  # Flatten ingress rules
  ingress_rules = flatten([
    for sg_name, sg_config in var.security_groups : [
      for idx, rule in lookup(sg_config, "ingress_rules", []) : merge(rule, {
        sg_name    = sg_name
        rule_index = idx
      })
    ]
  ])

  # Flatten egress rules
  egress_rules = flatten([
    for sg_name, sg_config in var.security_groups : [
      for idx, rule in lookup(sg_config, "egress_rules", []) : merge(rule, {
        sg_name    = sg_name
        rule_index = idx
      })
    ]
  ])
}
