# --------------------------------------------------------------------------------------------
# DNS Zone for external public consumption
# --------------------------------------------------------------------------------------------

module "r53_delegate" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/delegation-set"

  delegate_set_name = var.delegate_set_name
}

module "r53_public" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/public-zone"

  # Required variables
  search_domain = local.public_search_domain
  common_tags   = local.common_tags

  # Optional variables
  delegation_set_id = module.r53_delegate.id
  r53_tags          = var.r53_tags
}
