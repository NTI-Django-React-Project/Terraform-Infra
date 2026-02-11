output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_ids" {
  value = { for k, v in aws_subnet.this : k => v.id }
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  value = { for k, v in aws_nat_gateway.this : k => v.id }
}

output "route_table_ids" {
  value = { for k, v in aws_route_table.this : k => v.id }
}
