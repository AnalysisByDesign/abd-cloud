# --------------------------------------------------------------------------------------------
# Route53 Entries
# --------------------------------------------------------------------------------------------

module "r53-rds-rw" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/record"

  # Required variables
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "${format("%s-rw", var.name)}"
  type    = "CNAME"
  records = ["${aws_db_instance.rds.address}"]
}

module "r53-rds-ro" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/record"

  # Required variables
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "${format("%s-ro", var.name)}"
  type    = "CNAME"
  records = ["${aws_db_instance.rds.address}"]
}
