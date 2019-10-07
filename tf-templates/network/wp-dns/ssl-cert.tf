# --------------------------------------------------------------------------------------------
# ACM Certificate
# --------------------------------------------------------------------------------------------

module "ssl_cert" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/ssl-certs"

  required = "${var.ssl_cert_enabled}"

  acct_target        = "${var.acct_target}"
  acct_target_role   = "${var.acct_target_role}"
  certificate_region = "${var.target_region}"

  domain_name               = "${local.public_search_domain}"
  subject_alternative_names = ["${var.subject_alternative_names}"]

  r53_zone_id = "${module.r53_public.zone_id}"

  common_tags = "${local.common_tags}"
}
