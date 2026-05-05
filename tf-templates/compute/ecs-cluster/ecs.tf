# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------

# Create cluster
module "ecs-cluster" {
  source = "../../../../abd-cloud-modules/compute/ecs/cluster"

  name        = format("%s-%s", local.vpc_name, var.name)
  common_tags = local.common_tags
}
