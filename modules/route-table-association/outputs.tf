output "subnet_association_ids" {
  description = "Map of subnet association names to IDs"
  value       = { for k, v in aws_route_table_association.subnet : k => v.id }
}

output "gateway_association_ids" {
  description = "Map of gateway association names to IDs"
  value       = { for k, v in aws_route_table_association.gateway : k => v.id }
}

output "subnet_associations" {
  description = "Complete subnet association objects"
  value       = aws_route_table_association.subnet
}

output "gateway_associations" {
  description = "Complete gateway association objects"
  value       = aws_route_table_association.gateway
}
