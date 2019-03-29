# --------------------------------------------------------------------------------------------
# Route53 Entries
# --------------------------------------------------------------------------------------------

module "rds-aurora-rw" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/record"

  # Required variables
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "${format("%s-rw", var.name)}"
  type    = "CNAME"
  records = ["${aws_rds_cluster.this.endpoint}"]
}

module "rds-aurora-ro" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/record"

  # Required variables
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "${format("%s-ro", var.name)}"
  type    = "CNAME"
  records = ["${aws_rds_cluster.this.reader_endpoint}"]
}
