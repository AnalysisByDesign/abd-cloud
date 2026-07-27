# --------------------------------------------------------------------------------------------
# DNS Records for Website Access
# --------------------------------------------------------------------------------------------

module "dns_subdomain" {
  source = "../../../../abd-cloud-modules/network/dns/alias-record"
  count  = var.enable_wordpress && var.trg_lb_name != "" ? 1 : 0

  zone_id                      = data.aws_route53_zone.wordpress[0].zone_id
  name                         = var.wp_sub_domain
  alias_name                   = data.aws_lb.target[0].dns_name
  alias_zone_id                = data.aws_lb.target[0].zone_id
  alias_evaluate_target_health = false
}

module "dns_naked" {
  source = "../../../../abd-cloud-modules/network/dns/alias-record"
  count  = var.trg_lb_name != "" ? 1 : 0

  zone_id                      = module.r53_public.zone_id
  name                         = ""
  alias_name                   = data.aws_lb.target[0].dns_name
  alias_zone_id                = data.aws_lb.target[0].zone_id
  alias_evaluate_target_health = false
}

module "dns_www" {
  source = "../../../../abd-cloud-modules/network/dns/record"
  count  = var.enable_www_redirect ? 1 : 0

  zone_id = module.r53_public.zone_id
  name    = "www"
  type    = "CNAME"
  records = [local.public_search_domain]
}

module "dns_wildcard" {
  count = var.wildcard_dns_enabled && var.trg_lb_name != "" ? 1 : 0

  source = "../../../../abd-cloud-modules/network/dns/alias-record"

  zone_id                      = module.r53_public.zone_id
  name                         = "*"
  alias_name                   = data.aws_lb.target[0].dns_name
  alias_zone_id                = data.aws_lb.target[0].zone_id
  alias_evaluate_target_health = false
}

moved {
  from = module.dns_subdomain
  to   = module.dns_subdomain[0]
}

moved {
  from = module.dns_naked
  to   = module.dns_naked[0]
}

moved {
  from = module.dns_www
  to   = module.dns_www[0]
}
