# --------------------------------------------------------------------------------------------
# Scheduled instance refresh
# Optional recurring refresh (e.g. a weekly drill), started by EventBridge Scheduler calling
# StartInstanceRefresh directly through its universal target, so no Lambda is needed.
# A CLI or API refresh ignores the ASG's instance_refresh settings, so the preferences are
# passed explicitly from the same variables.
# --------------------------------------------------------------------------------------------

locals {
  scheduled_refresh = var.asg_scheduled_refresh_expression != "" ? 1 : 0
}

resource "aws_scheduler_schedule" "instance_refresh" {
  count = local.scheduled_refresh

  name        = format("%s-%s-instance-refresh", local.vpc_name, var.name)
  description = format("Scheduled instance refresh of ASG %s-%s", local.vpc_name, var.name)

  schedule_expression          = var.asg_scheduled_refresh_expression
  schedule_expression_timezone = var.asg_scheduled_refresh_timezone

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:autoscaling:startInstanceRefresh"
    role_arn = aws_iam_role.scheduled_refresh[0].arn

    # Unset (null) preferences are left out so the API applies its own defaults
    input = jsonencode({
      AutoScalingGroupName = module.autoscaling-group.name
      Preferences = { for k, v in {
        MinHealthyPercentage = var.asg_instance_refresh_min_healthy_percentage
        MaxHealthyPercentage = var.asg_instance_refresh_max_healthy_percentage
        InstanceWarmup       = var.asg_instance_refresh_instance_warmup
      } : k => v if v != null }
    })

    # A refresh already in progress makes the call fail; retry briefly, never for a day
    retry_policy {
      maximum_event_age_in_seconds = 3600
      maximum_retry_attempts       = 2
    }
  }
}

# --------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {
  count = local.scheduled_refresh
}

data "aws_iam_policy_document" "scheduled_refresh_assume" {
  count = local.scheduled_refresh

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current[0].account_id]
    }
  }
}

data "aws_iam_policy_document" "scheduled_refresh" {
  count = local.scheduled_refresh

  statement {
    actions   = ["autoscaling:StartInstanceRefresh"]
    resources = [module.autoscaling-group.arn]
  }
}

resource "aws_iam_role" "scheduled_refresh" {
  count = local.scheduled_refresh

  name               = format("%s-%s-instance-refresh", local.vpc_name, var.name)
  description        = format("EventBridge Scheduler role to start instance refreshes of ASG %s-%s", local.vpc_name, var.name)
  assume_role_policy = data.aws_iam_policy_document.scheduled_refresh_assume[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy" "scheduled_refresh" {
  count = local.scheduled_refresh

  name   = "start-instance-refresh"
  role   = aws_iam_role.scheduled_refresh[0].id
  policy = data.aws_iam_policy_document.scheduled_refresh[0].json
}
