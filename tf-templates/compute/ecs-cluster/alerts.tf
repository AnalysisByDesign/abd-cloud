# --------------------------------------------------------------------------------------------
# ECS alerts
# Failures only, one rule each so every email is readable text, not the raw event:
#   deployment-failed  a deployment failed (including circuit breaker rollbacks)
#   service-error      ECS cannot place a service's tasks, or another service error
#   task-not-started   a task failed to start (image pull, secrets, mounts)
#   task-exited        a task's essential container exited with a non-zero code
# A container that exits 0 is a task that finished its job (the scheduled wp-cron runs
# every 5 minutes), so it is not an alert. Routine stops by the scheduler (deployments,
# scale in, draining) are left out too.
#
# The input templates are EventBridge text templates: each quoted line is one line of the
# email. A path missing from an event leaves its variable out, so each rule only uses
# fields its events always carry.
# --------------------------------------------------------------------------------------------

locals {
  ecs_alerts_console = format(
    "https://%s.console.aws.amazon.com/ecs/v2/clusters/%s/services?region=%s",
    var.target_region, module.ecs-cluster.cluster_name, var.target_region
  )

  ecs_alerts_task_paths = {
    group          = "$.detail.group"
    taskDefinition = "$.detail.taskDefinitionArn"
    startedBy      = "$.detail.startedBy"
    stoppedAt      = "$.detail.stoppedAt"
    stopCode       = "$.detail.stopCode"
    stoppedReason  = "$.detail.stoppedReason"
    az             = "$.detail.availabilityZone"
    task           = "$.detail.taskArn"
  }

  ecs_alerts_task_lines = [
    "Task:        <group>",
    "Definition:  <taskDefinition>",
    "Started by:  <startedBy>",
    "Stopped:     <stoppedAt> in <az>",
    "Why:         <stopCode>: <stoppedReason>",
  ]

  ecs_alerts_footer = [
    "Task ARN:    <task>",
    "",
    format("Logs:        CloudWatch log groups under /ecs/%s/", local.vpc_name),
    format("Console:     %s", local.ecs_alerts_console),
  ]

  ecs_alerts = {
    deployment-failed = {
      description = "ECS deployments that failed"
      pattern = {
        "detail-type" = ["ECS Deployment State Change"]
        detail        = { eventName = ["SERVICE_DEPLOYMENT_FAILED"] }
      }
      paths = {
        service    = "$.resources[0]"
        reason     = "$.detail.reason"
        deployment = "$.detail.deploymentId"
        time       = "$.time"
      }
      lines = [
        format("ECS deployment failed in %s", module.ecs-cluster.cluster_name),
        "",
        "Service:     <service>",
        "Deployment:  <deployment>",
        "Time:        <time>",
        "Reason:      <reason>",
        "",
        "The service stays on the new revision with no tasks if it never started one; redeploy a working image.",
        format("Console:     %s", local.ecs_alerts_console),
      ]
    }

    service-error = {
      description = "ECS service errors, such as tasks that cannot be placed"
      pattern = {
        "detail-type" = ["ECS Service Action"]
        detail        = { eventType = ["ERROR"] }
      }
      paths = {
        service = "$.resources[0]"
        event   = "$.detail.eventName"
        time    = "$.time"
      }
      lines = [
        format("ECS service error in %s: <event>", module.ecs-cluster.cluster_name),
        "",
        "Service:     <service>",
        "Event:       <event>",
        "Time:        <time>",
        "",
        format("Console:     %s", local.ecs_alerts_console),
      ]
    }

    task-not-started = {
      description = "ECS tasks that failed to start"
      pattern = {
        "detail-type" = ["ECS Task State Change"]
        detail = {
          clusterArn = [module.ecs-cluster.cluster_arn]
          lastStatus = ["STOPPED"]
          stopCode   = ["TaskFailedToStart"]
        }
      }
      paths = local.ecs_alerts_task_paths
      lines = concat(
        [format("ECS task failed to start in %s: <group>", module.ecs-cluster.cluster_name), ""],
        local.ecs_alerts_task_lines,
        local.ecs_alerts_footer,
      )
    }

    task-exited = {
      description = "ECS tasks whose essential container exited with a non-zero code"
      pattern = {
        "detail-type" = ["ECS Task State Change"]
        detail = {
          clusterArn = [module.ecs-cluster.cluster_arn]
          lastStatus = ["STOPPED"]
          stopCode   = ["EssentialContainerExited"]
          # Matches when any container in the task has a non-zero exit code
          containers = { exitCode = [{ "anything-but" = 0 }] }
        }
      }
      paths = merge(local.ecs_alerts_task_paths, {
        container = "$.detail.containers[0].name"
        exitCode  = "$.detail.containers[0].exitCode"
      })
      lines = concat(
        [format("ECS task failed in %s: <group>", module.ecs-cluster.cluster_name), ""],
        local.ecs_alerts_task_lines,
        ["Container:   <container>, exit code <exitCode> (137 is killed, often out of memory)"],
        local.ecs_alerts_footer,
      )
    }
  }
}

resource "aws_cloudwatch_event_rule" "ecs_alerts" {
  # Keys only: the alerts' patterns differ in shape, so they cannot be one map's values
  for_each = toset(var.enable_alerts ? keys(local.ecs_alerts) : [])

  name          = format("%s-ecs-%s", module.ecs-cluster.cluster_name, each.key)
  description   = format("%s in cluster %s", local.ecs_alerts[each.key].description, module.ecs-cluster.cluster_name)
  event_pattern = jsonencode(merge({ source = ["aws.ecs"] }, local.ecs_alerts[each.key].pattern))

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "ecs_alerts" {
  for_each = aws_cloudwatch_event_rule.ecs_alerts

  rule = each.value.name
  arn  = data.aws_sns_topic.alerts[0].arn

  input_transformer {
    input_paths = local.ecs_alerts[each.key].paths
    # One quoted string per line. Not jsonencode, which escapes < and > and so would
    # break the <variable> placeholders; the lines hold no quotes or backslashes.
    input_template = join("\n", [for l in local.ecs_alerts[each.key].lines : format("\"%s\"", l)])
  }
}
