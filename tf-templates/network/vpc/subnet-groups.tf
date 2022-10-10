# --------------------------------------------------------------------------------------------
# Subnet Groups
# --------------------------------------------------------------------------------------------

module "db-subnet-group" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/db-subnet-group"

  count       = length(var.private_db_subnets) > 0 ? 1 : 0
  name        = format("%s-%s", var.vpc_name, var.db_subnet_group_name)
  description = "Subnet group for databases"
  common_tags = local.common_tags
  subnet_ids  = ["${aws_subnet.private-db.*.id}"]
  subnet_tags = var.db_subnet_tags
}

module "cache-subnet-group" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//network/cache-subnet-group"

  count       = length(var.private_cache_subnets) > 0 ? 1 : 0
  name        = format("%s-%s", var.vpc_name, var.cache_subnet_group_name)
  description = "Subnet group for cache"
  subnet_ids  = ["${aws_subnet.private-cache.*.id}"]
}
