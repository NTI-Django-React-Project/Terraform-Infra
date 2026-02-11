output "attachment_ids" {
  description = "Map of attachment names to IDs"
  value       = { for k, v in aws_iam_group_policy_attachment.this : k => v.id }
}

output "attachments" {
  description = "Complete IAM group policy attachment objects"
  value       = aws_iam_group_policy_attachment.this
}
