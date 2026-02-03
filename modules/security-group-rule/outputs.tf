output "rule_ids" {
  value = {
    for k, r in aws_security_group_rule.this : k => r.id
  }
}
