output "user_names" {
  description = "Map of user keys to user names"
  value       = { for k, v in aws_iam_user.this : k => v.name }
}

output "user_arns" {
  description = "Map of user names to ARNs"
  value       = { for k, v in aws_iam_user.this : k => v.arn }
}

output "user_unique_ids" {
  description = "Map of user names to unique IDs"
  value       = { for k, v in aws_iam_user.this : k => v.unique_id }
}

output "access_key_ids" {
  description = "Map of user names to access key IDs"
  value       = { for k, v in aws_iam_access_key.this : k => v.id }
  sensitive   = true
}

output "secret_access_keys" {
  description = "Map of user names to secret access keys"
  value       = { for k, v in aws_iam_access_key.this : k => v.secret }
  sensitive   = true
}

output "users" {
  description = "Complete IAM user objects"
  value       = aws_iam_user.this
}
