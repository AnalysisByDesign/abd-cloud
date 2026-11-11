# --------------------------------------------------------------------------------------------
# ACM Certificate
# --------------------------------------------------------------------------------------------

module "ssl_cert" {
  source = "../../../../abd-cloud-modules/security/ssl-certs"

  # Module declares its own provider so cannot take count; required gates its resources
  required = var.enable_load_balancer

  acct_target        = var.acct_target
  acct_target_role   = var.acct_target_role
  certificate_region = var.target_region

  domain_name               = local.public_search_domain
  subject_alternative_names = ["*.${local.public_search_domain}"]

  r53_zone_id = try(data.aws_route53_zone.public[0].id, "")

  common_tags = local.common_tags
}
