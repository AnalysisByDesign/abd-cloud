# --------------------------------------------------------------------------------------------
# Local variables
# --------------------------------------------------------------------------------------------
locals {
  snapshot_identifier = data.aws_db_cluster_snapshot.cluster_snapshot.id
}
