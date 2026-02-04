# ────────────────────────────── VPC ──────────────────────────────
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, { Name = "${var.tags["Project"]}-vpc" })
}

# ────────────────────────────── Subnets ──────────────────────────────
resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge(var.tags, {
    Name = each.key
    Type = each.value.type
    Tier = each.value.tier
    AZ   = each.value.availability_zone
  })
}

# ────────────────────────────── Internet Gateway ──────────────────────────────
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.tags["Project"]}-igw" })
}

# ────────────────────────────── NAT Gateways ──────────────────────────────
resource "aws_eip" "nat" {
  for_each = var.nat_gateways

  domain = "vpc"

  tags = merge(var.tags, { Name = "${each.key}-eip" })
}

resource "aws_nat_gateway" "this" {
  for_each = var.nat_gateways

  allocation_id     = aws_eip.nat[each.key].id
  subnet_id         = aws_subnet.this[each.value.subnet_key].id
  connectivity_type = "public"

  tags = merge(var.tags, each.value.tags, { Name = each.key })

  depends_on = [aws_eip.nat, aws_internet_gateway.this]
}

# ────────────────────────────── Route Tables ──────────────────────────────
resource "aws_route_table" "this" {
  for_each = {
    for type in distinct([for s in var.subnets : s.type]) :
    type => { name = "${type}-rt" }
  }

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = each.value.name, Type = each.key })
}

# ────────────────────────────── Routes ──────────────────────────────
# Public subnets → IGW
resource "aws_route" "public" {
  for_each = { for k, v in aws_route_table.this : k => v if v.tags["Type"] == "public" }

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Private subnets → NAT
resource "aws_route" "private" {
  for_each = { for k, v in aws_route_table.this : k => v if v.tags["Type"] == "private" }

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = values(aws_nat_gateway.this)[0].id
}

# ────────────────────────────── Route Table Associations ──────────────────────────────
resource "aws_route_table_association" "this" {
  for_each = aws_subnet.this

  subnet_id      = each.value.id
  route_table_id = aws_route_table.this[each.value.tags["Type"]].id
}
