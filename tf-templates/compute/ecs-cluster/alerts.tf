# --------------------------------------------------------------------------------------------
# ECS alerts
# Deployment failures (including circuit breaker rollbacks), tasks ECS cannot place, and
# tasks that fail to start or whose essential container exits. Routine stops by the
# scheduler (deployments, scale in, draining) are left out.
# --------------------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "ecs_alerts" {
  count = var.enable_alerts ? 1 : 0

  name        = format("%s-ecs-alerts", module.ecs-cluster.cluster_name)
  description = format("ECS failures in cluster %s", module.ecs-cluster.cluster_name)

  event_pattern = jsonencode({
    source = ["aws.ecs"]
    "$or" = [
      {
        "detail-type" = ["ECS Deployment State Change"]
        detail        = { eventName = ["SERVICE_DEPLOYMENT_FAILED"] }
      },
      {
        "detail-type" = ["ECS Service Action"]
        detail        = { eventType = ["ERROR"] }
      },
      {
        "detail-type" = ["ECS Task State Change"]
        detail = {
          clusterArn = [module.ecs-cluster.cluster_arn]
          lastStatus = ["STOPPED"]
          stopCode   = ["TaskFailedToStart", "EssentialContainerExited"]
        }
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "ecs_alerts" {
  count = var.enable_alerts ? 1 : 0

  rule = aws_cloudwatch_event_rule.ecs_alerts[0].name
  arn  = data.aws_sns_topic.alerts[0].arn
}
