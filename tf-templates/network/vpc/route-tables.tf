# --------------------------------------------------------------------------------------------
# Public Route Table
# --------------------------------------------------------------------------------------------

# Adopt the Default RouteTable and use it as Public routing.
resource "aws_default_route_table" "public" {
  default_route_table_id = aws_vpc.this.default_route_table_id
  propagating_vgws       = ["${var.public_propagating_vgws}"]

  tags = (merge(local.common_tags, var.public_route_table_tags,
  map("Name", format("%s-public", var.vpc_name))))
}

# --------------------------------------------------------------------------------------------

resource "aws_route" "public_internet_gateway" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_default_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# --------------------------------------------------------------------------------------------
# Private Route Table
# There are as many route-tables as the largest amount of subnets of each type (really?)
# --------------------------------------------------------------------------------------------

resource "aws_route_table" "private" {
  count = (max(length(var.private_web_subnets),
    length(var.private_app_subnets),
    length(var.private_cache_subnets),
  length(var.private_db_subnets)))

  vpc_id           = aws_vpc.this.id
  propagating_vgws = ["${var.private_propagating_vgws}"]

  tags = (merge(local.common_tags, var.private_route_table_tags,
  map("Name", format("%s-private-%s", var.vpc_name, element(var.azs, count.index)))))

  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    ignore_changes = ["propagating_vgws"]
  }
}

# --------------------------------------------------------------------------------------------

resource "aws_route" "private_nat_gateway" {
  count = (var.enable_nat_gateway ?
    (max(length(var.private_web_subnets),
      length(var.private_app_subnets),
      length(var.private_cache_subnets),
    length(var.private_db_subnets)))
  : 0)

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = (element(aws_nat_gateway.this.*.id,
    (length(aws_nat_gateway.this.*.id)
  < 2 ? 0 : count.index)))
}
