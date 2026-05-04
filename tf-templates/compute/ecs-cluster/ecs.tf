# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------

# Create cluster
module "ecs-cluster" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//compute/ecs/cluster"

  name        = format("%s-%s", local.vpc_name, var.name)
  common_tags = local.common_tags
}
