# --------------------------------------------------------------------------------------------
# CloudWatch Log Groups
# --------------------------------------------------------------------------------------------

module "cloudwatch_groups" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//monitoring/cloudwatch/group"

  common_tags     = "${local.common_tags}"
  cloudwatch_tags = "${var.cloudwatch_tags}"

  cloudwatch_loggroup_names = ["${var.cloudwatch_loggroup_names}"]
}
