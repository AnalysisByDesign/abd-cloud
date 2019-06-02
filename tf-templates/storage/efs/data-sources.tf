# -----------------------------------------------------------------------------
# efs-data-sources.tf
# -----------------------------------------------------------------------------

data "aws_subnet" "this" {
  count      = "${length(var.private_db_subnets)}"
  cidr_block = "${element(var.private_db_subnets, count.index)}"
}

# -----------------------------------------------------------------------------

# The route53 zone for the EFS volume really should be private :)
data "aws_route53_zone" "this" {
  name         = "int.${local.public_search_domain}."
  private_zone = true
}
