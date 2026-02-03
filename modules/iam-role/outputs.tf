output "arn" {
  description = "The ARN of the IAM role."
  value       = aws_iam_role.this.arn
}

output "name" {
  description = "The name of the IAM role."
  value       = aws_iam_role.this.name
}

output "id" {
  description = "The ID of the IAM role."
  value       = aws_iam_role.this.id
}

output "unique_id" {
  description = "The unique ID assigned by AWS to the IAM role."
  value       = aws_iam_role.this.unique_id
}

output "create_date" {
  description = "The creation date of the IAM role."
  value       = aws_iam_role.this.create_date
}
