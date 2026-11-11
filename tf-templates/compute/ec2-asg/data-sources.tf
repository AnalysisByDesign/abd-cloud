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
