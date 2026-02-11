output "security_group_ids" {
  description = "Map of security group names to IDs"
  value       = { for k, v in aws_security_group.this : k => v.id }
}

output "security_group_arns" {
  description = "Map of security group names to ARNs"
  value       = { for k, v in aws_security_group.this : k => v.arn }
}

output "security_group_names" {
  description = "Map of security group keys to names"
  value       = { for k, v in aws_security_group.this : k => v.name }
}

output "security_groups" {
  description = "Complete security group objects"
  value       = aws_security_group.this
}
