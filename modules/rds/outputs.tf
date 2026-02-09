output "db_instance_ids" {
  description = "Map of DB instance names to IDs"
  value       = { for k, v in aws_db_instance.this : k => v.id }
}

output "db_instance_arns" {
  description = "Map of DB instance names to ARNs"
  value       = { for k, v in aws_db_instance.this : k => v.arn }
}

output "db_instance_endpoints" {
  description = "Map of DB instance names to connection endpoints"
  value       = { for k, v in aws_db_instance.this : k => v.endpoint }
}

output "db_instance_addresses" {
  description = "Map of DB instance names to addresses"
  value       = { for k, v in aws_db_instance.this : k => v.address }
}

output "db_instance_hosted_zone_ids" {
  description = "Map of DB instance names to hosted zone IDs"
  value       = { for k, v in aws_db_instance.this : k => v.hosted_zone_id }
}

output "db_instance_resource_ids" {
  description = "Map of DB instance names to resource IDs"
  value       = { for k, v in aws_db_instance.this : k => v.resource_id }
}

output "db_instance_ports" {
  description = "Map of DB instance names to ports"
  value       = { for k, v in aws_db_instance.this : k => v.port }
}

output "db_instance_engines" {
  description = "Map of DB instance names to engines"
  value       = { for k, v in aws_db_instance.this : k => v.engine }
}

output "db_instance_engine_versions" {
  description = "Map of DB instance names to engine versions"
  value       = { for k, v in aws_db_instance.this : k => v.engine_version_actual }
}

output "db_subnet_group_ids" {
  description = "Map of DB subnet group names to IDs"
  value       = { for k, v in aws_db_subnet_group.this : k => v.id }
}

output "db_subnet_group_arns" {
  description = "Map of DB subnet group names to ARNs"
  value       = { for k, v in aws_db_subnet_group.this : k => v.arn }
}

output "db_instances" {
  description = "Complete DB instance objects"
  value       = aws_db_instance.this
  sensitive   = true
}

output "master_user_secrets" {
  value = {
    for k, db in aws_db_instance.this :
    k => db.master_user_secret[0].secret_arn
  }
}