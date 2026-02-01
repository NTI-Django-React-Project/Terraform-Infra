output "route_table_ids" {
  description = "Map of route table names to IDs"
  value       = { for k, v in aws_route_table.this : k => v.id }
}

output "route_table_arns" {
  description = "Map of route table names to ARNs"
  value       = { for k, v in aws_route_table.this : k => v.arn }
}

output "route_tables" {
  description = "Complete route table objects"
  value       = aws_route_table.this
}
