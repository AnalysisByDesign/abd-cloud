# --------------------------------------------------------------------------------------------
# DB-Param-Groups
# --------------------------------------------------------------------------------------------

module "db-param-group" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//database/param-group"

  count            = "${var.db_param_group_name == "" ? 0 : 1 }"
  name             = "${format("%s-%s", var.vpc_name, var.db_param_group_name)}"
  description      = "Parameter group for databases"
  common_tags      = "${local.common_tags}"
  param_group_tags = "${var.db_param_group_tags}"
}

module "db-cluster-param-group" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//database/cluster-param-group"

  count            = "${var.db_param_group_name == "" ? 0 : 1 }"
  name             = "${format("%s-%s", var.vpc_name, var.db_param_group_name)}"
  description      = "Cluster parameter group for databases"
  common_tags      = "${local.common_tags}"
  param_group_tags = "${var.db_param_group_tags}"
}
