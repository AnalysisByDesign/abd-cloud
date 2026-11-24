# --------------------------------------------------------------------------------------------
# Local variables
# --------------------------------------------------------------------------------------------

locals {
  alerts_topic_enabled     = var.alerts_topic_name != ""
  budget_ec2_daily_enabled = var.budget_ec2_daily_limit > 0

  # The topic needs its own policy once any AWS service publishes to it
  alerts_policy_enabled = local.alerts_topic_enabled && (var.alerts_allow_eventbridge || local.budget_ec2_daily_enabled)
}
