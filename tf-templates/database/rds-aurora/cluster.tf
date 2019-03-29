# -----------------------------------------------------------------------------
# aurora-cluster.tf
# -----------------------------------------------------------------------------

resource "aws_rds_cluster" "this" {
  cluster_identifier              = "${format("%s-%s", local.vpc_name, var.name)}"
  engine                          = "${var.engine}"
  engine_version                  = "${var.engine_version}"
  engine_mode                     = "${var.engine_mode}"
  port                            = "${var.port}"
  enabled_cloudwatch_logs_exports = "${var.cloudwatch_logging}"

  db_subnet_group_name            = "${format("%s-%s", local.vpc_name, var.subnet_group_name)}"
  db_cluster_parameter_group_name = "${format("%s-%s", local.vpc_name, var.param_group_name)}"

  vpc_security_group_ids = ["${module.rds-aurora.id}"]

  database_name     = "${var.schema_name}"
  master_username   = "${var.admin_name}"
  master_password   = "${var.admin_password}"
  storage_encrypted = "${var.storage_encrypted}"
  kms_key_id        = "${var.kms_key_id}"

  iam_roles                           = ["${var.iam_roles}"]
  iam_database_authentication_enabled = "${var.iam_authentication_enabled}"

  backtrack_window             = "${var.backtrack_window}"
  backup_retention_period      = "${var.backup_retention}"
  preferred_backup_window      = "${var.backup_window}"
  preferred_maintenance_window = "${var.maintenance_window}"

  snapshot_identifier       = "${var.snapshot_identifier}"
  skip_final_snapshot       = "${var.skip_final_snapshot}"
  final_snapshot_identifier = "${format("%s-%s", local.vpc_name, var.final_snapshot_identifier)}"

  apply_immediately = "${var.apply_immediately}"

  tags = "${merge(local.common_tags, 
                    var.rds_tags, 
                    map("Name", format("%s-%s", local.vpc_name, var.name)))}"
}
