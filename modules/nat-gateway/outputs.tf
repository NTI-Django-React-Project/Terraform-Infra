output "nat_gateway_ids" {
  description = "Map of NAT Gateway names to IDs"
  value       = { for k, v in aws_nat_gateway.this : k => v.id }
}

output "nat_gateway_public_ips" {
  description = "Map of NAT Gateway names to public IPs"
  value       = { for k, v in aws_nat_gateway.this : k => v.public_ip }
}

output "nat_gateway_private_ips" {
  description = "Map of NAT Gateway names to private IPs"
  value       = { for k, v in aws_nat_gateway.this : k => v.private_ip }
}

output "eip_ids" {
  description = "Map of NAT Gateway names to EIP IDs"
  value       = { for k, v in aws_eip.nat : k => v.id }
}

output "eip_public_ips" {
  description = "Map of NAT Gateway names to EIP public IPs"
  value       = { for k, v in aws_eip.nat : k => v.public_ip }
}

output "eip_allocation_ids" {
  description = "Map of NAT Gateway names to EIP allocation IDs"
  value       = { for k, v in aws_eip.nat : k => v.allocation_id }
}

output "nat_gateways" {
  description = "Complete NAT Gateway objects"
  value       = aws_nat_gateway.this
}
