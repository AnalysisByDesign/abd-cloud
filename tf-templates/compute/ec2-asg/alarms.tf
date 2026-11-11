# --------------------------------------------------------------------------------------------
# CloudWatch Alarms
# Optional ASG health alarms, notifying the account-wide alerts SNS topic
# --------------------------------------------------------------------------------------------

data "aws_sns_topic" "alerts" {
  count = var.enable_alarms ? 1 : 0
  name  = var.alerts_topic_name
}

# No InService instances, e.g. a failed replacement or a stuck lifecycle hook
resource "aws_cloudwatch_metric_alarm" "no_in_service_instances" {
  count = var.enable_alarms ? 1 : 0

  alarm_name        = format("%s-%s-no-in-service-instances", local.vpc_name, var.name)
  alarm_description = format("ASG %s-%s has no InService instances", local.vpc_name, var.name)

  namespace   = "AWS/AutoScaling"
  metric_name = "GroupInServiceInstances"
  dimensions = {
    AutoScalingGroupName = module.autoscaling-group.name
  }

  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 3
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  treat_missing_data  = "breaching"

  alarm_actions = [data.aws_sns_topic.alerts[0].arn]
  ok_actions    = [data.aws_sns_topic.alerts[0].arn]

  tags = local.common_tags
}

# Any instance in the ASG failing its EC2 status checks
resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  count = var.enable_alarms ? 1 : 0

  alarm_name        = format("%s-%s-status-check-failed", local.vpc_name, var.name)
  alarm_description = format("An instance in ASG %s-%s is failing its EC2 status checks", local.vpc_name, var.name)

  namespace   = "AWS/EC2"
  metric_name = "StatusCheckFailed"
  dimensions = {
    AutoScalingGroupName = module.autoscaling-group.name
  }

  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  alarm_actions = [data.aws_sns_topic.alerts[0].arn]
  ok_actions    = [data.aws_sns_topic.alerts[0].arn]

  tags = local.common_tags
}
