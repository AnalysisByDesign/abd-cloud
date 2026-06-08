# --------------------------------------------------------------------------------------------
# EFS
# --------------------------------------------------------------------------------------------
module "efs" {
  source = "../../../../abd-cloud-modules/storage/efs"

  # Required variables
  name               = format("%s-%s", local.vpc_name, var.name)
  route53_name       = var.name
  subnet_ids         = data.aws_subnet.this[*].id
  security_group_ids = [module.efs-sg.id]
  route53_zone_id    = data.aws_route53_zone.this.id
  common_tags        = local.common_tags

  # Optional variables
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  encrypted        = var.encrypted
  kms_key_id       = var.kms_key_id
  efs_tags         = var.efs_tags

  lifecycle_policy_transition_to_ia                    = var.lifecycle_policy_transition_to_ia
  lifecycle_policy_transition_to_archive               = var.lifecycle_policy_transition_to_archive
  lifecycle_policy_transition_to_primary_storage_class = var.lifecycle_policy_transition_to_primary_storage_class

}
