# --------------------------------------------------------------------------------------------
#  Elasticache-Param-Group
# --------------------------------------------------------------------------------------------

module "cache-cluster-param-group" {
  source = "../../../../abd-cloud-modules/cache/cluster-param-group"

  count              = var.cache_cluster_param_group_name == "" ? 0 : 1
  name               = format("%s-%s", var.vpc_name, var.cache_cluster_param_group_name)
  description        = "Cluster parameter group for cache databases"
  elasticache_family = "redis4.0"
}
