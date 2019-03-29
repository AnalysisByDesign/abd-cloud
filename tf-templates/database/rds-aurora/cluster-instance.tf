# -----------------------------------------------------------------------------
# rds-cluster-instance.tf
# -----------------------------------------------------------------------------

resource "aws_rds_cluster_instance" "this" {
  count = "${1 + var.read_replica_count}"

  cluster_identifier = "${aws_rds_cluster.this.id}"
  engine             = "${var.engine}"
  engine_version     = "${var.engine_version}"

  instance_class    = "${var.instance_class}"
  identifier_prefix = "${format("%s-%s-", local.vpc_name, var.name)}"

  publicly_accessible     = false
  db_subnet_group_name    = "${format("%s-%s", local.vpc_name, var.subnet_group_name)}"
  db_parameter_group_name = "${format("%s-%s", local.vpc_name, var.param_group_name)}"

  preferred_maintenance_window = "${var.maintenance_window}"

  monitoring_role_arn = "${data.aws_iam_role.rds_monitoring.arn}"
  monitoring_interval = "${var.monitoring_interval}"

  performance_insights_enabled    = "${var.performance_insights_enabled}"
  performance_insights_kms_key_id = "${var.performance_insights_kms_key_id}"
  auto_minor_version_upgrade      = false

  tags = "${merge(local.common_tags, 
                    var.rds_tags, 
                    map("Name", format("%s-%s", local.vpc_name, var.name)))}"
}
