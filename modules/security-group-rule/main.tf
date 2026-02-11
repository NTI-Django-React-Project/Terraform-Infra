resource "aws_security_group_rule" "this" {
  for_each = var.rules

  type              = each.value.type
  security_group_id = each.value.security_group_id

  from_port = each.value.from_port
  to_port   = each.value.to_port
  protocol  = each.value.protocol

  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)

  description = lookup(each.value, "description", null)
}
