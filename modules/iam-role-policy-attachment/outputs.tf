output "role_name" {
  description = "The name of the IAM role to which policies are attached."
  value       = var.role_name
}

output "policy_arns" {
  description = "List of policy ARNs attached to the role."
  value       = var.policy_arns
}

output "attachment_ids" {
  description = "Map of policy ARNs to their attachment IDs."
  value       = { for k, v in aws_iam_role_policy_attachment.this : k => v.id }
}
