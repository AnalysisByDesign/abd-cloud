# --------------------------------------------------------------------------------------------
# DNS Records for Website Access
# --------------------------------------------------------------------------------------------

module "dns_subdomain" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/alias-record"

  zone_id                      = data.aws_route53_zone.wordpress.zone_id
  name                         = var.wp_sub_domain
  alias_name                   = data.aws_lb.wordpress.dns_name
  alias_zone_id                = data.aws_lb.wordpress.zone_id
  alias_evaluate_target_health = false
}

module "dns_naked" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/alias-record"

  zone_id                      = module.r53_public.zone_id
  name                         = ""
  alias_name                   = data.aws_lb.wordpress.dns_name
  alias_zone_id                = data.aws_lb.wordpress.zone_id
  alias_evaluate_target_health = false
}

module "dns_www" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/record"

  zone_id = module.r53_public.zone_id
  name    = "www"
  type    = "CNAME"
  records = ["${local.public_search_domain}"]
}
