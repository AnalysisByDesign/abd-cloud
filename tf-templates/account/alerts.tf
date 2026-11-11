# --------------------------------------------------------------------------------------------
# Alerting SNS Topic
# Account-wide topic for CloudWatch alarm notifications. Subscriptions (e.g. email) are
# added manually, as email subscriptions need confirming by the recipient anyway.
# --------------------------------------------------------------------------------------------

resource "aws_sns_topic" "alerts" {
  count = var.alerts_topic_name != "" ? 1 : 0

  name = var.alerts_topic_name

  tags = merge(local.common_tags, var.alerts_tags)
}
