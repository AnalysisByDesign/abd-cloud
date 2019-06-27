# --------------------------------------------------------------------------------------------
# Route53 Entries
#
# Inbound HTTP/s requests go like this...
# - http://abd-wordpress.uk/        -> Load Balancer 
# - ALB http                        -> https://abd-wordpress.uk/
# - https://abd-wordpress.uk/       -> Load Balancer
#
# --------------------------------------------------------------------------------------------

# Load Balancer frontend traffic - http(s)://abd-wordpress.uk/ -> Load Balancer
module "dns_load_balancer" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/alias-record"

  zone_id                      = "${data.aws_route53_zone.public.zone_id}"
  name                         = ""
  alias_name                   = "${module.load_balancer.alb_dns_name}"
  alias_zone_id                = "${module.load_balancer.alb_zone_id}"
  alias_evaluate_target_health = false
}
