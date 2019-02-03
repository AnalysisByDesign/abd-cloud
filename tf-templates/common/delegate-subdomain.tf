# --------------------------------------------------------------------------------------------
# Connection details for the apex zone which is in the production account
# --------------------------------------------------------------------------------------------
provider "aws" {
  alias = "apex"

  version = "~> 1.31"

  region = "${var.target_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.acct_apex}:role/${var.acct_target_role == "" ? "aws_admin" : var.acct_target_role}"
  }
}

data "aws_route53_zone" "apex" {
  provider     = "aws.apex"
  count        = "${var.delegation_enabled ? 1 : 0}"
  name         = "${var.public_apex_domain}."
  private_zone = false
}

# -----------------------------------------------------------------------------
# Should we create an NS record in our apex to delegate this subdomain?
# Using a dedicated resource here due to requiring an alternate provider
# -----------------------------------------------------------------------------
resource "aws_route53_record" "this" {
  provider = "aws.apex"

  count = "${var.delegation_enabled 
                  ? (var.use_existing_zones ? 0 : length(local.public_sub_domains)) 
                  : 0}"

  zone_id = "${data.aws_route53_zone.apex.zone_id}"
  name    = "${local.public_sub_domains[count.index]}"
  type    = "NS"

  ttl     = "86400"
  records = ["${module.r53-public.name_servers[count.index]}"]

  lifecycle {
    create_before_destroy = true
  }
}
