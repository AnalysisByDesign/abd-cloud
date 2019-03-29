# --------------------------------------------------------------------------------------------
# Data Sources
# --------------------------------------------------------------------------------------------

data "aws_route53_zone" "private" {
  name         = "int.${local.public_search_domain}."
  private_zone = true
}

data "aws_iam_role" "rds_monitoring" {
  name = "rds-enhanced-monitoring"
}

output "monitor_role" {
  value = "${data.aws_iam_role.rds_monitoring.arn}"
}
