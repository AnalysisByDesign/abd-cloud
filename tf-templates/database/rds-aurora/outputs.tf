# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

# Aurora Cluster
output "cluster_arn" {
  description = "The ARN of the Aurora Cluster"
  value       = "${aws_rds_cluster.this.arn}"
}

output "cluster_id" {
  description = "The id of the Aurora Cluster"
  value       = "${aws_rds_cluster.this.id}"
}

output "cluster_endpoint" {
  description = "The endpoint of the Aurora Cluster"
  value       = "${aws_rds_cluster.this.endpoint}"
}

output "cluster_reader_endpoint" {
  description = "The reader_endpoint of the Aurora Cluster"
  value       = "${aws_rds_cluster.this.reader_endpoint}"
}

output "cluster_hosted_zone_id" {
  description = "The hosted_zone_id of the Aurora Cluster"
  value       = "${aws_rds_cluster.this.hosted_zone_id}"
}

# Aurora Instances
output "instance_arns" {
  description = "The ARNs of the Aurora Instances"
  value       = "${join(",",aws_rds_cluster.this.*.arn)}"
}

output "instance_ids" {
  description = "The IDs of the Aurora Instances"
  value       = "${join(",",aws_rds_cluster.this.*.id)}"
}

output "instance_endpoints" {
  description = "The Endpoints of the Aurora Instances"
  value       = "${join(",",aws_rds_cluster.this.*.endpoint)}"
}
