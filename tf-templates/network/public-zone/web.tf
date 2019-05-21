# --------------------------------------------------------------------------------------------
# DNS Records for Website Access
# --------------------------------------------------------------------------------------------

module "dns-ip4-website-naked" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/record"

  required = "${var.web_ip4 != "" ? 1 : 0}"

  zone_id = "${module.r53_public.zone_id}"
  name    = ""
  type    = "A"
  records = ["${var.web_ip4}"]
}

module "dns-ip4-website-www" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/record"

  required = "${var.web_ip4 != "" ? 1 : 0}"

  zone_id = "${module.r53_public.zone_id}"
  name    = "www"
  type    = "A"
  records = ["${var.web_ip4}"]
}

module "dns-ip6-website-naked" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/record"

  required = "${var.web_ip6 != "" ? 1 : 0}"

  zone_id = "${module.r53_public.zone_id}"
  name    = ""
  type    = "AAAA"
  records = ["${var.web_ip6}"]
}

module "dns-ip6-website-www" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/record"

  required = "${var.web_ip6 != "" ? 1 : 0}"

  zone_id = "${module.r53_public.zone_id}"
  name    = "www"
  type    = "AAAA"
  records = ["${var.web_ip6}"]
}
