# --------------------------------------------------------------------------------------------
# DNS
# --------------------------------------------------------------------------------------------

module "r53_delegate" {
  source = "../../../abd-cloud-modules/network/dns/delegation-set"

  delegate_set_name = var.delegate_set_name
}

module "r53_public" {
  source = "../../../abd-cloud-modules/network/dns/public-zone"

  # Required variables
  search_domain = local.public_search_domain
  common_tags   = local.common_tags

  # Optional variables
  delegation_set_id = module.r53_delegate.id
  r53_tags          = var.r53_tags
}

module "r53_mx" {
  source = "../../../abd-cloud-modules/network/dns/record"

  required = length(var.mx_records) > 0 ? 1 : 0
  zone_id  = module.r53_public.zone_id
  name     = ""
  type     = "MX"
  ttl      = "300"
  records  = var.mx_records
}
