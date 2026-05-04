# --------------------------------------------------------------------------------------------
# Route53 Entries
# --------------------------------------------------------------------------------------------

module "dns_apex" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/alias-record"

  # Required variables
  zone_id                      = data.aws_route53_zone.public.zone_id
  name                         = ""
  alias_name                   = module.load_balancer.alb_dns_name
  alias_zone_id                = module.load_balancer.alb_zone_id
  alias_evaluate_target_health = false
}
