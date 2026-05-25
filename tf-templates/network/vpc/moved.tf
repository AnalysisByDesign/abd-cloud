# --------------------------------------------------------------------------------------------
# Moved blocks — added count to module calls during Terraform 1.x upgrade.
# These migrate state from the bare module address to the [0]-indexed address.
# Safe to retain indefinitely; they are a no-op once state is already at the new address.
# --------------------------------------------------------------------------------------------

moved {
  from = module.cache-cluster-param-group
  to   = module.cache-cluster-param-group[0]
}

moved {
  from = module.cache-subnet-group
  to   = module.cache-subnet-group[0]
}

moved {
  from = module.db-cluster-param-group-provisioned
  to   = module.db-cluster-param-group-provisioned[0]
}

moved {
  from = module.db-cluster-param-group-serverless
  to   = module.db-cluster-param-group-serverless[0]
}

moved {
  from = module.db-param-group
  to   = module.db-param-group[0]
}

moved {
  from = module.db-subnet-group
  to   = module.db-subnet-group[0]
}
