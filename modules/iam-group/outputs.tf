output "group_names" {
  description = "Map of group keys to group names"
  value       = { for k, v in aws_iam_group.this : k => v.name }
}

output "group_arns" {
  description = "Map of group names to ARNs"
  value       = { for k, v in aws_iam_group.this : k => v.arn }
}

output "group_unique_ids" {
  description = "Map of group names to unique IDs"
  value       = { for k, v in aws_iam_group.this : k => v.unique_id }
}

output "groups" {
  description = "Complete IAM group objects"
  value       = aws_iam_group.this
}
