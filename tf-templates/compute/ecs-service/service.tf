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
