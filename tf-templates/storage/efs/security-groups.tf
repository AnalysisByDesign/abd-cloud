# --------------------------------------------------------------------------------------------
# Security Groups
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
# EFS Security Group
# --------------------------------------------------------------------------------------------
module "efs-sg" "efs" {
  source = "../../../../abd-cloud-modules/security/security-group"

  # Required variables
  name        = format("%s-%s-efs", local.vpc_name, var.name)
  description = format("%s-%s-efs", local.vpc_name, var.name)
  common_tags = local.common_tags
  vpc_id      = data.aws_vpc.vpc.id
}
