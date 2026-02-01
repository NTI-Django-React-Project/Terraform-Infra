
resource "aws_route_table_association" "subnet" {
  for_each = var.subnet_associations

  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}

resource "aws_route_table_association" "gateway" {
  for_each = var.gateway_associations

  gateway_id     = each.value.gateway_id
  route_table_id = each.value.route_table_id
}
