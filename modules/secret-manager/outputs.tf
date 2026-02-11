output "secret_ids" {
  description = "Map of secret names to secret IDs"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.id }
}

output "secret_arns" {
  description = "Map of secret names to secret ARNs"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}

output "secret_names" {
  description = "Map of secret keys to secret names"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.name }
}

output "secret_version_ids" {
  description = "Map of secret names to secret version IDs"
  value       = { for k, v in aws_secretsmanager_secret_version.this : k => v.version_id }
}

output "secrets" {
  description = "Complete secret objects (does NOT contain secret_string values)"
  value       = aws_secretsmanager_secret.this
}
