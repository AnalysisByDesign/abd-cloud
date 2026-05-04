# --------------------------------------------------------------------------------------------
# Route table association
# --------------------------------------------------------------------------------------------

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_default_route_table.public.id
}

# --------------------------------------------------------------------------------------------

resource "aws_route_table_association" "private-web" {
  count = length(var.private_web_subnets)

  subnet_id      = element(aws_subnet.private-web.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route_table_association" "private-app" {
  count = length(var.private_app_subnets)

  subnet_id      = element(aws_subnet.private-app.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route_table_association" "private-cache" {
  count = length(var.private_cache_subnets)

  subnet_id      = element(aws_subnet.private-cache.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route_table_association" "private-db" {
  count = length(var.private_db_subnets)

  subnet_id      = element(aws_subnet.private-db.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}
