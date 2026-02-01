output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value       = { for k, v in aws_subnet.this : k => v.id }
}

output "subnet_arns" {
  description = "Map of subnet names to subnet ARNs"
  value       = { for k, v in aws_subnet.this : k => v.arn }
}

output "subnet_cidr_blocks" {
  description = "Map of subnet names to CIDR blocks"
  value       = { for k, v in aws_subnet.this : k => v.cidr_block }
}

output "subnet_availability_zones" {
  description = "Map of subnet names to availability zones"
  value       = { for k, v in aws_subnet.this : k => v.availability_zone }
}

output "subnets" {
  description = "Complete subnet objects"
  value       = aws_subnet.this
}
