# --------------------------------------------------------------------------------------------
# ACM Certificate
# --------------------------------------------------------------------------------------------

module "ssl_cert" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/ssl-certs"

  required = true

  acct_target        = "${var.acct_target}"
  acct_target_role   = "${var.acct_target_role}"
  certificate_region = "${var.target_region}"

  domain_name               = "${local.public_search_domain}"
  subject_alternative_names = ["*.${local.public_search_domain}"]

  r53_zone_id = "${data.aws_route53_zone.public.id}"

  common_tags = "${local.common_tags}"
}

module "ssl_cert_cloudfront" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/ssl-certs"

  required = true

  acct_target        = "${var.acct_target}"
  acct_target_role   = "${var.acct_target_role}"
  certificate_region = "us-east-1"

  domain_name               = "${local.public_search_domain}"
  subject_alternative_names = ["*.${local.public_search_domain}"]
  r53_zone_id               = "${data.aws_route53_zone.public.id}"
  common_tags               = "${local.common_tags}"
}
