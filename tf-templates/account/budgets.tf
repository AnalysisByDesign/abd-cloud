# --------------------------------------------------------------------------------------------
# EC2 daily cost budget
# Alerts the account's alerts topic when one day's EC2 compute spend goes over a limit. It is
# a tripwire for runaway capacity, such as a Batch compute environment that keeps launching
# instances that never become usable. It never stops anything. AWS Budgets updates several
# times a day, several hours behind the spend, so expect the alert hours after it starts.
# Gross usage is measured, with credits and refunds left out, so a credit cannot hide a spike.
# --------------------------------------------------------------------------------------------

resource "aws_budgets_budget" "ec2_daily" {
  count = local.budget_ec2_daily_enabled ? 1 : 0

  name         = format("%s-ec2-daily", var.account_name)
  budget_type  = "COST"
  time_unit    = "DAILY"
  limit_amount = format("%.2f", var.budget_ec2_daily_limit)
  limit_unit   = "USD"

  cost_filter {
    name   = "Service"
    values = ["Amazon Elastic Compute Cloud - Compute"]
  }

  cost_types {
    include_credit = false
    include_refund = false
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.alerts[0].arn]
  }

  tags = merge(local.common_tags, var.alerts_tags)

  lifecycle {
    precondition {
      condition     = local.alerts_topic_enabled
      error_message = "budget_ec2_daily_limit needs alerts_topic_name set, as the budget notifies the alerts topic."
    }
  }

  depends_on = [aws_sns_topic_policy.alerts]
}
