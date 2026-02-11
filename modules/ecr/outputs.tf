output "repository_arns" {
  description = "Map of repository names to ARNs"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "repository_urls" {
  description = "Map of repository names to URLs"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_registry_ids" {
  description = "Map of repository names to registry IDs"
  value       = { for k, v in aws_ecr_repository.this : k => v.registry_id }
}

output "repositories" {
  description = "Complete ECR repository objects"
  value       = aws_ecr_repository.this
}
