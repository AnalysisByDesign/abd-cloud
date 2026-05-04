# --------------------------------------------------------------------------------------------
# DNS Records for Email Provision
# --------------------------------------------------------------------------------------------

module "r53_mx" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/record"

  required = length(var.mx_records) > 0 ? 1 : 0
  zone_id  = module.r53_public.zone_id
  name     = ""
  type     = "MX"
  ttl      = "300"
  records  = ["${var.mx_records}"]
}
