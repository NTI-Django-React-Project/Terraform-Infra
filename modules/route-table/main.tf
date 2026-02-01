
resource "aws_route_table" "this" {
  for_each = var.route_tables

  vpc_id = var.vpc_id

  dynamic "route" {
    for_each = lookup(each.value, "routes", [])
    content {
      cidr_block                 = lookup(route.value, "cidr_block", null)
      ipv6_cidr_block            = lookup(route.value, "ipv6_cidr_block", null)
      destination_prefix_list_id = lookup(route.value, "destination_prefix_list_id", null)
      gateway_id                 = lookup(route.value, "gateway_id", null)
      nat_gateway_id             = lookup(route.value, "nat_gateway_id", null)
      network_interface_id       = lookup(route.value, "network_interface_id", null)
      transit_gateway_id         = lookup(route.value, "transit_gateway_id", null)
      vpc_peering_connection_id  = lookup(route.value, "vpc_peering_connection_id", null)
      egress_only_gateway_id     = lookup(route.value, "egress_only_gateway_id", null)
      carrier_gateway_id         = lookup(route.value, "carrier_gateway_id", null)
      local_gateway_id           = lookup(route.value, "local_gateway_id", null)
      vpc_endpoint_id            = lookup(route.value, "vpc_endpoint_id", null)
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}
