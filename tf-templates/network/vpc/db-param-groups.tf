# --------------------------------------------------------------------------------------------
# DB-Param-Groups
# --------------------------------------------------------------------------------------------

module "db-cluster-param-group-provisioned" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//database/cluster-param-group"

  count            = "${var.db_param_group_name == "" ? 0 : 1 }"
  name             = "${format("%s-%s", var.vpc_name, var.db_param_group_name)}"
  description      = "Cluster parameter group for databases"
  common_tags      = "${local.common_tags}"
  param_group_tags = "${var.db_param_group_tags}"
}

module "db-cluster-param-group-serverless" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//database/cluster-param-group"

  count            = "${var.db_param_group_name == "" ? 0 : 1 }"
  name             = "${format("%s-%s-serverless", var.vpc_name, var.db_param_group_name)}"
  description      = "Cluster parameter group for databases"
  db_family        = "aurora5.6"
  common_tags      = "${local.common_tags}"
  param_group_tags = "${var.db_param_group_tags}"
}

module "db-param-group" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//database/param-group"

  count       = "${var.db_param_group_name == "" ? 0 : 1 }"
  name        = "${format("%s-%s", var.vpc_name, var.db_param_group_name)}"
  description = "Parameter group for databases"

  db_family        = "mysql5.7"
  query_cache_type = 0
  query_cache_size = 0

  common_tags      = "${local.common_tags}"
  param_group_tags = "${var.db_param_group_tags}"
}
