output "role_arns" {
  description = "Map of service account names to IAM role ARNs"
  value       = { for k, v in aws_iam_role.irsa : k => v.arn }
  sensitive   = false
}

output "service_account_names" {
  description = "Map of service account names"
  value       = { for k, v in var.service_accounts : k => v.k8s_sa_name }
}