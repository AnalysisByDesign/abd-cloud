# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_subnet" "lb" {
  count      = length(var.public_subnets)
  cidr_block = element(var.public_subnets, count.index)
}

data "aws_subnet" "asg" {
  count      = length(var.private_app_subnets)
  cidr_block = element(var.private_app_subnets, count.index)
}

locals {
  asg_tier_subnets = var.asg_subnet_tier == "public" ? data.aws_subnet.lb : data.aws_subnet.asg
  asg_subnet_ids = [
    for s in local.asg_tier_subnets : s.id
    if length(var.asg_availability_zones) == 0 || contains(var.asg_availability_zones, s.availability_zone)
  ]
}

# -----------------------------------------------------------------------------
# Private route tables the instances manage (one per AZ, named by the network/vpc template)

data "aws_route_table" "managed" {
  for_each = toset(var.managed_route_table_azs)
  vpc_id   = local.vpc_id

  tags = {
    Name = format("%s-private-%s", local.vpc_name, each.key)
  }
}

locals {
  managed_route_tables = [for az in var.managed_route_table_azs : data.aws_route_table.managed[az]]

  # Values every user data and IAM policy template can use, alongside extra_template_vars
  computed_template_vars = {
    asg_name         = format("%s-%s", local.vpc_name, var.name)
    route_table_ids  = join(" ", local.managed_route_tables[*].id)
    route_table_arns = jsonencode(local.managed_route_tables[*].arn)
  }
}

# -----------------------------------------------------------------------------

data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.asg_ami_image_glob]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.asg_ami_image_owner]
}

# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

data "aws_security_group" "rds" {
  count = var.rds_security_group == "" ? 0 : 1
  name  = format("%s-%s", local.vpc_name, var.rds_security_group)
}

data "aws_security_group" "efs" {
  count = var.efs_security_group == "" ? 0 : 1
  name  = format("%s-%s", local.vpc_name, var.efs_security_group)
}

# -----------------------------------------------------------------------------

data "aws_route53_zone" "public" {
  count = var.enable_load_balancer ? 1 : 0
  name  = "${local.public_search_domain}."
}
