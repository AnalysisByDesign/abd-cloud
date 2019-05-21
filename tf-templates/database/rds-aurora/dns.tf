# --------------------------------------------------------------------------------------------
# Route53 Entries
# --------------------------------------------------------------------------------------------

module "r53-aurora-rw" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/record"

  # Required variables
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "${format("%s-rw", var.name)}"
  type    = "CNAME"
  records = ["${concat(aws_rds_cluster.provisioned.*.endpoint, aws_rds_cluster.serverless.*.endpoint)}"]
}

module "r53-aurora-ro" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/dns/record"

  # Required variables
  zone_id = "${data.aws_route53_zone.private.zone_id}"
  name    = "${format("%s-ro", var.name)}"
  type    = "CNAME"
  records = ["${concat(aws_rds_cluster.provisioned.*.reader_endpoint, aws_rds_cluster.serverless.*.endpoint)}"]
}
