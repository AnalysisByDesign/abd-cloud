# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------

# Create cluster
module "ecs-cluster" {
  source = "../../../../abd-cloud-modules/compute/ecs/cluster"

  name         = format("%s-%s", local.vpc_name, var.name)
  common_tags  = local.common_tags
  ecs_insights = var.ecs_insights

  # Managed scaling, termination protection and draining are on (module defaults)
  capacity_providers = {
    for name, cp in local.capacity_providers : name => {
      auto_scaling_group_arn    = local.host_asg_arns[name]
      target_capacity           = cp.target_capacity
      maximum_scaling_step_size = cp.maximum_scaling_step_size
      instance_warmup_period    = cp.instance_warmup_period
    }
  }

  default_capacity_provider_strategy = [
    for name, cp in local.capacity_providers : {
      capacity_provider = name
      base              = cp.base
      weight            = cp.weight
    } if cp.include_in_default
  ]
}

# -----------------------------------------------------------------------------
# Service discovery: services in awsvpc mode register A records here
# (e.g. smtp.abd-wordpress.internal)
# -----------------------------------------------------------------------------

resource "aws_service_discovery_private_dns_namespace" "this" {
  count = var.service_discovery_namespace != "" ? 1 : 0

  name        = var.service_discovery_namespace
  description = format("Service discovery for %s", module.ecs-cluster.cluster_name)
  vpc         = local.vpc_id

  tags = local.common_tags
}
