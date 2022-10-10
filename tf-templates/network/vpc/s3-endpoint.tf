# --------------------------------------------------------------------------------------------
# S3 VPC Endpoint
# --------------------------------------------------------------------------------------------

resource "aws_vpc_endpoint" "s3" {
  count = (var.vpc_endpoint_s3_enable
    || var.vpc_endpoint_s3_web_enable
    || var.vpc_endpoint_s3_app_enable
  ? 1 : 0)

  vpc_id       = aws_vpc.this.id
  service_name = format("com.amazonaws.%s.s3", var.target_region)
}

# Do we want to associate with all private route tables
resource "aws_vpc_endpoint_route_table_association" "s3_rt" {
  count = (var.vpc_endpoint_s3_enable
    ? max(length(var.private_web_subnets),
      length(var.private_app_subnets),
      length(var.private_cache_subnets),
      length(var.private_db_subnets)
    )
  : 0)

  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = element(aws_route_table.private.*.id, count.index)
}

# Do we want to use subnet associations just for the web subnet?
resource "aws_vpc_endpoint_subnet_association" "s3_web_subnet" {
  count = var.vpc_endpoint_s3_web_enable ? length(var.private_web_subnets) : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  subnet_id       = element(aws_subnet.private-web.*.id, count.index)
}

# Do we want to use subnet associations just for the app subnet?
resource "aws_vpc_endpoint_subnet_association" "s3_app_subnet" {
  count = var.vpc_endpoint_s3_app_enable ? length(var.private_app_subnets) : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  subnet_id       = element(aws_subnet.private-app.*.id, count.index)
}
