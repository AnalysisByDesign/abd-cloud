# --------------------------------------------------------------------------------------------
# IAM Roles
# --------------------------------------------------------------------------------------------

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

# RDS Enhanced Monitoring Role Enabled at account level
module "rds_monitoring_role" "rds_enhanced" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/iam-role"

  required = "${var.newrelic_required}"

  roles = [{
    name               = "rds-enhanced-monitoring"
    description        = "Allows RDS enhanced monitoring"
    assume_role_policy = "${data.aws_iam_policy_document.rds_enhanced.json}"
    policy_arn         = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  }]
}
