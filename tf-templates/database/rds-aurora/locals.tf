# --------------------------------------------------------------------------------------------
# Local variables
# --------------------------------------------------------------------------------------------
locals {
  snapshot_identifier = "${coalesce(data.aws_db_cluster_snapshot.cluster_snapshot.id, "")}"
}
