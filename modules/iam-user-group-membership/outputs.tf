output "membership_ids" {
  description = "Map of membership names to IDs"
  value       = { for k, v in aws_iam_user_group_membership.this : k => v.id }
}

output "memberships" {
  description = "Complete IAM user group membership objects"
  value       = aws_iam_user_group_membership.this
}
