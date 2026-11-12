# --------------------------------------------------------------------------------------------
# Alarms: the service has no healthy targets behind the ALB (WP-04 ruling 11). The ALB
# metric is free, unlike Container Insights' running task count.
# --------------------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "no_healthy_targets" {
  count = local.alarms ? 1 : 0

  alarm_name          = format("%s-no-healthy-targets", local.full_name)
  alarm_description   = format("Service %s has no healthy targets behind the ALB", local.full_name)
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 3
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = data.aws_lb.this[0].arn_suffix
    TargetGroup  = aws_lb_target_group.this[0].arn_suffix
  }

  alarm_actions = [data.aws_sns_topic.alerts[0].arn]
  ok_actions    = [data.aws_sns_topic.alerts[0].arn]

  tags = local.common_tags
}
