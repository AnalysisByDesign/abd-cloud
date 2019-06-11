# -----------------------------------------------------------------------------
# rds-mysql.tf
# -----------------------------------------------------------------------------

resource "aws_db_instance" "rds" {
  engine         = "${var.engine}"
  engine_version = "${var.engine_version}"

  instance_class    = "${var.instance_class}"
  identifier_prefix = "${format("%s-%s-", local.vpc_name, var.name)}"

  storage_encrypted = "${var.storage_encrypted}"
  allocated_storage = "${var.allocated_storage}"
  storage_type      = "${var.storage_type}"

  port                 = "${var.port}"
  multi_az             = false
  publicly_accessible  = false
  db_subnet_group_name = "${format("%s-%s", local.vpc_name, var.subnet_group_name)}"

  parameter_group_name = "${format("%s-%s", local.vpc_name, var.param_group_name)}"

  username = "${var.admin_name}"
  password = "${var.admin_password}"
  name     = "${var.schema_name}"

  iam_database_authentication_enabled = "${var.iam_authentication_enabled}"
  kms_key_id                          = "${var.kms_key_id}"
  vpc_security_group_ids              = ["${module.sg-rds-mysql.id}"]

  backup_retention_period = "${var.backup_retention}"
  backup_window           = "${var.backup_window}"
  maintenance_window      = "${var.maintenance_window}"

  enabled_cloudwatch_logs_exports = "${var.cloudwatch_logging}"
  monitoring_role_arn             = "${data.aws_iam_role.rds_monitoring.arn}"
  monitoring_interval             = "${var.monitoring_interval}"

  #  performance_insights_enabled    = "${var.performance_insights_enabled}"
  #  performance_insights_kms_key_id = "${var.performance_insights_kms_key_id}"

  #  snapshot_identifier       = "${local.snapshot_identifier}"
  skip_final_snapshot       = "${var.skip_final_snapshot}"
  final_snapshot_identifier = "${format("%s-%s", local.vpc_name, var.final_snapshot_identifier)}"
  apply_immediately           = "${var.apply_immediately}"
  auto_minor_version_upgrade  = false
  allow_major_version_upgrade = false
  lifecycle {
    ignore_changes = ["snapshot_identifier"]
  }
  copy_tags_to_snapshot = true
  tags = "${merge(local.common_tags, 
                    var.rds_tags, 
                    map("Name", format("%s-%s", local.vpc_name, var.name)))}"
}
