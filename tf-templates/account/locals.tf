# --------------------------------------------------------------------------------------------
# Local variables
# --------------------------------------------------------------------------------------------

locals {
  alerts_topic_enabled     = var.alerts_topic_name != ""
  budget_ec2_daily_enabled = var.budget_ec2_daily_limit > 0

  # USD amounts that each send an alert; with none given, alert at the limit
  budget_ec2_daily_alert_amounts = length(var.budget_ec2_daily_alert_amounts) > 0 ? var.budget_ec2_daily_alert_amounts : [var.budget_ec2_daily_limit]

  # The topic needs its own policy once any AWS service publishes to it
  alerts_policy_enabled = local.alerts_topic_enabled && (var.alerts_allow_eventbridge || local.budget_ec2_daily_enabled)
}
