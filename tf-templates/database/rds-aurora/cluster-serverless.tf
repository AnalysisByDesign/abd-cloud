# -----------------------------------------------------------------------------
# aurora-cluster.tf
# -----------------------------------------------------------------------------

resource "aws_rds_cluster" "serverless" {
  count = var.engine_mode == "serverless" ? 1 : 0

  cluster_identifier = format("%s-%s", local.vpc_name, var.name)
  engine             = "aurora"
  engine_mode        = "serverless"
  port               = "3306"

  scaling_configuration = ["${var.scaling_configuration}"]

  db_subnet_group_name            = format("%s-%s", local.vpc_name, var.subnet_group_name)
  db_cluster_parameter_group_name = format("%s-%s-serverless", local.vpc_name, var.param_group_name)

  vpc_security_group_ids = ["${module.sg-aurora.id}"]

  database_name     = var.schema_name
  master_username   = var.admin_name
  master_password   = var.admin_password
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  iam_roles                           = ["${var.iam_roles}"]
  iam_database_authentication_enabled = var.iam_authentication_enabled

  backtrack_window        = var.backtrack_window
  backup_retention_period = var.backup_retention

  #  preferred_maintenance_window = "${var.maintenance_window}"

  snapshot_identifier       = local.snapshot_identifier
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = format("%s-%s", local.vpc_name, var.final_snapshot_identifier)
  apply_immediately         = var.apply_immediately
  lifecycle {
    ignore_changes = ["snapshot_identifier"]
  }
  tags = (merge(local.common_tags,
    var.rds_tags,
  map("Name", format("%s-%s", local.vpc_name, var.name))))
}
