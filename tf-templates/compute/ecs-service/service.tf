# --------------------------------------------------------------------------------------------
# ECS service
# --------------------------------------------------------------------------------------------

module "service" {
  source = "../../../../abd-cloud-modules/compute/ecs/service"

  name            = var.name
  cluster_id      = data.aws_ecs_cluster.this.arn
  task_definition = module.task.definition_arn
  common_tags     = local.common_tags

  task_definition_managed_externally = var.task_definition_managed_externally

  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_circuit_breaker         = true

  # No launch type: the strategy given here, or the cluster's default strategy
  launch_type                = null
  capacity_provider_strategy = var.capacity_provider_strategy
  ordered_placement_strategy = local.awsvpc ? [for s in var.ordered_placement_strategy : s if s.type != "binpack"] : var.ordered_placement_strategy

  health_check_grace_period_seconds = local.load_balanced ? var.health_check_grace_period_seconds : null
  load_balancers = local.load_balanced ? [{
    target_group_arn = aws_lb_target_group.this[0].arn
    container_name   = local.lb_container
    container_port   = local.lb_port
  }] : []

  subnet_ids         = local.awsvpc ? data.aws_subnet.app[*].id : []
  security_group_ids = local.awsvpc ? [aws_security_group.awsvpc[0].id] : []

  service_registries = local.service_discovery ? [{
    registry_arn = aws_service_discovery_service.this[0].arn
  }] : []

  enable_execute_command = var.enable_execute_command

  # The listener rule must exist before ECS registers tasks in the target group
  depends_on = [aws_lb_listener_rule.this]
}

# --------------------------------------------------------------------------------------------
# awsvpc mode: the task's own security group, and its Cloud Map A record
# --------------------------------------------------------------------------------------------

resource "aws_security_group" "awsvpc" {
  count = local.awsvpc ? 1 : 0

  name        = format("%s-ecs-%s", local.vpc_name, var.name)
  description = format("Terraform - ECS service %s", local.full_name)
  vpc_id      = local.vpc_id

  tags = merge(local.common_tags, { Name = format("%s-ecs-%s", local.vpc_name, var.name) })
}

resource "aws_vpc_security_group_ingress_rule" "awsvpc" {
  for_each = local.awsvpc && length(var.awsvpc_ingress_cidr_blocks) > 0 ? {
    for pair in setproduct(var.awsvpc_ingress_ports, var.awsvpc_ingress_cidr_blocks) :
    "${pair[0]}-${pair[1]}" => { port = pair[0], cidr = pair[1] }
  } : {}

  security_group_id = aws_security_group.awsvpc[0].id
  description       = format("Terraform - %s inbound", var.name)
  ip_protocol       = "tcp"
  from_port         = each.value.port
  to_port           = each.value.port
  cidr_ipv4         = each.value.cidr
}

resource "aws_vpc_security_group_egress_rule" "awsvpc" {
  count = local.awsvpc ? 1 : 0

  security_group_id = aws_security_group.awsvpc[0].id
  description       = "Terraform - Outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_service_discovery_service" "this" {
  count = local.service_discovery ? 1 : 0

  name = var.service_discovery_name != "" ? var.service_discovery_name : var.name

  dns_config {
    namespace_id   = data.aws_service_discovery_dns_namespace.this[0].id
    routing_policy = "MULTIVALUE"

    dns_records {
      type = "A"
      ttl  = 10
    }
  }

  tags = local.common_tags
}

# --------------------------------------------------------------------------------------------
# Scheduled tasks (e.g. WP-Cron, WP-05 ruling 7): EventBridge Scheduler runs the family's
# latest ACTIVE revision with one container's command overridden
# --------------------------------------------------------------------------------------------

locals {
  # The family ARN without a revision: RunTask takes its latest ACTIVE revision, which is
  # the one CI last registered
  family_arn = format("arn:aws:ecs:%s:%s:task-definition/%s", var.target_region, local.account_id, local.full_name)
}

data "aws_iam_policy_document" "scheduler_assume" {
  count = length(var.scheduled_tasks) > 0 ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

data "aws_iam_policy_document" "scheduler" {
  count = length(var.scheduled_tasks) > 0 ? 1 : 0

  statement {
    sid       = "RunOwnTask"
    actions   = ["ecs:RunTask"]
    resources = [local.family_arn, "${local.family_arn}:*"]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [data.aws_ecs_cluster.this.arn]
    }
  }

  statement {
    sid       = "TagOwnTask"
    actions   = ["ecs:TagResource"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ecs:CreateAction"
      values   = ["RunTask"]
    }
  }

  statement {
    sid       = "PassOwnRoles"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.execution.arn, aws_iam_role.task.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  count = length(var.scheduled_tasks) > 0 ? 1 : 0

  name               = format("%s-ecs-%s-scheduler", local.vpc_name, var.name)
  description        = format("EventBridge Scheduler role for service %s", local.full_name)
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy" "scheduler" {
  count = length(var.scheduled_tasks) > 0 ? 1 : 0

  name   = "service"
  role   = aws_iam_role.scheduler[0].id
  policy = data.aws_iam_policy_document.scheduler[0].json
}

resource "aws_scheduler_schedule" "this" {
  for_each = var.scheduled_tasks

  name        = format("%s-%s", local.full_name, each.key)
  description = format("Terraform - %s for service %s", each.key, local.full_name)

  schedule_expression          = each.value.schedule
  schedule_expression_timezone = each.value.timezone

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = data.aws_ecs_cluster.this.arn
    role_arn = aws_iam_role.scheduler[0].arn

    ecs_parameters {
      task_definition_arn = local.family_arn
      task_count          = 1
      propagate_tags      = "TASK_DEFINITION"
      group               = format("scheduled:%s", each.key)

      # The cluster's default capacity provider strategy, as for the service
      dynamic "capacity_provider_strategy" {
        for_each = var.capacity_provider_strategy
        content {
          capacity_provider = capacity_provider_strategy.value.capacity_provider
          weight            = capacity_provider_strategy.value.weight
          base              = capacity_provider_strategy.value.base
        }
      }

      dynamic "network_configuration" {
        for_each = local.awsvpc ? [1] : []
        content {
          subnets          = data.aws_subnet.app[*].id
          security_groups  = [aws_security_group.awsvpc[0].id]
          assign_public_ip = false
        }
      }
    }

    # The named container runs the command instead of its default; any other containers in
    # the task start as usual
    input = jsonencode({
      containerOverrides = [{ name = each.value.container, command = each.value.command }]
    })

    retry_policy {
      maximum_retry_attempts = 0
    }
  }
}
