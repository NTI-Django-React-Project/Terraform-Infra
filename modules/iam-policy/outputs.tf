output "policy_ids" {
  description = "Map of policy names to IDs"
  value       = { for k, v in aws_iam_policy.this : k => v.id }
}

output "policy_arns" {
  description = "Map of policy names to ARNs"
  value       = { for k, v in aws_iam_policy.this : k => v.arn }
}

output "policy_names" {
  description = "Map of policy keys to policy names"
  value       = { for k, v in aws_iam_policy.this : k => v.name }
}

output "policies" {
  description = "Complete IAM policy objects"
  value       = aws_iam_policy.this
}
