# --------------------------------------------------------------------------------------------
# Route53
# --------------------------------------------------------------------------------------------

module "r53_private" "zone" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/private-zone"

  use_existing_zones = "${var.use_existing_zones}"

  # Required variables
  vpc_id         = "${aws_vpc.this.id}"
  search_domains = ["${formatlist("int.%s.%s", local.public_sub_domains, var.public_apex_domain)}"]
  common_tags    = "${local.common_tags}"

  # Optional variables
  r53_tags = "${var.r53_tags}"
}

# Route53 Public Sub-Domain -----------------------------------------------------------------

module "r53_delegate" "set" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/delegation-set"

  use_existing_zones = "${var.use_existing_zones}"

  delegate_set_name = "${var.delegate_set_name}"
}

module "r53_public" "zone" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/public-zone"

  use_existing_zones = "${var.use_existing_zones}"

  # Required variables
  search_domains = ["${formatlist("%s.%s", local.public_sub_domains, var.public_apex_domain)}"]
  common_tags    = "${local.common_tags}"

  # Optional variables
  delegation_set_id = "${module.r53_delegate.id}"
  r53_tags          = "${var.r53_tags}"
}

# --------------------------------------------------------------------------------------------
# Do we need to add additional VPC links to a private zone?
data "aws_route53_zone" "existing" {
  count        = "${var.use_existing_zones ? 1 : 0}"
  name         = "int.${local.public_search_domain}."
  private_zone = true
}

resource "aws_route53_zone_association" "secondary" {
  count   = "${var.use_existing_zones ? 1 : 0}"
  zone_id = "${data.aws_route53_zone.existing.zone_id}"
  vpc_id  = "${aws_vpc.this.id}"
}
