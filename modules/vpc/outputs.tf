output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "default_security_group_id" {
  description = "The ID of the default security group"
  value       = aws_vpc.this.default_security_group_id
}

output "default_route_table_id" {
  description = "The ID of the default route table"
  value       = aws_vpc.this.default_route_table_id
}

output "enable_dns_support" {
  description = "Whether DNS support is enabled"
  value       = aws_vpc.this.enable_dns_support
}

output "enable_dns_hostnames" {
  description = "Whether DNS hostnames are enabled"
  value       = aws_vpc.this.enable_dns_hostnames
}
