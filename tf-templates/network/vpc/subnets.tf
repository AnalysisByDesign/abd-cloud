# --------------------------------------------------------------------------------------------
# Public Subnets
# --------------------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = var.map_public_ip

  tags = (merge(local.common_tags, var.subnet_tags,
  map("Name", format("%s-public-%s", var.vpc_name, element(var.azs, count.index)))))
}

# --------------------------------------------------------------------------------------------
# Private Web Subnets
# --------------------------------------------------------------------------------------------
resource "aws_subnet" "private-web" {
  count = length(var.private_web_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.private_web_subnets, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false

  tags = (merge(local.common_tags, var.subnet_tags,
  map("Name", format("%s-pvt-web-%s", var.vpc_name, element(var.azs, count.index)))))
}

# --------------------------------------------------------------------------------------------
# Private App Subnets
# --------------------------------------------------------------------------------------------
resource "aws_subnet" "private-app" {
  count = length(var.private_app_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.private_app_subnets, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false

  tags = (merge(local.common_tags, var.subnet_tags,
  map("Name", format("%s-pvt-app-%s", var.vpc_name, element(var.azs, count.index)))))
}

# --------------------------------------------------------------------------------------------
# Private Cache Subnets
# --------------------------------------------------------------------------------------------
resource "aws_subnet" "private-cache" {
  count = length(var.private_cache_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.private_cache_subnets, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false

  tags = (merge(local.common_tags, var.subnet_tags,
  map("Name", format("%s-pvt-cache-%s", var.vpc_name, element(var.azs, count.index)))))
}

# --------------------------------------------------------------------------------------------
# Private DB Subnets
# --------------------------------------------------------------------------------------------
resource "aws_subnet" "private-db" {
  count = length(var.private_db_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.private_db_subnets, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false

  tags = (merge(local.common_tags, var.subnet_tags,
  map("Name", format("%s-pvt-db-%s", var.vpc_name, element(var.azs, count.index)))))
}
