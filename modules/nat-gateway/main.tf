terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_eip" "nat" {
  for_each = var.nat_gateways

  domain = "vpc"

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${each.key}-eip"
    }
  )
}

resource "aws_nat_gateway" "this" {
  for_each = var.nat_gateways

  allocation_id     = aws_eip.nat[each.key].id
  subnet_id         = each.value.subnet_id
  connectivity_type = var.connectivity_type

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
    }
  )

  depends_on = [aws_eip.nat]
}
