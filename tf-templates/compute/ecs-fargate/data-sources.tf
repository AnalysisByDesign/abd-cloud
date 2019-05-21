# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_subnet" "lb" {
  count      = "${length(var.public_subnets)}"
  cidr_block = "${element(var.public_subnets, count.index)}"
}

data "aws_subnet" "asg" {
  count      = "${length(var.private_app_subnets)}"
  cidr_block = "${element(var.private_app_subnets, count.index)}"
}

# -----------------------------------------------------------------------------

data "aws_security_group" "rds" {
  name = "${format("%s-%s", local.vpc_name, var.rds_security_group)}"
}

# -----------------------------------------------------------------------------

data "aws_route53_zone" "public" {
  name = "${local.public_search_domain}."
}

# -----------------------------------------------------------------------------

