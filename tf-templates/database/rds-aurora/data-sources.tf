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

data "aws_db_cluster_snapshot" "rds_final_snapshot" {
  db_cluster_identifier = "${format("%s-%s", local.vpc_name, var.name)}"
  snapshot_type         = "manual"
  most_recent           = true
}
