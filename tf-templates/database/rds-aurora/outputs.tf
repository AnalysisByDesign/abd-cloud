# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

# Aurora Cluster
output "cluster_arn" {
  description = "The ARN of the Aurora Cluster"
  value       = "${join("", concat(aws_rds_cluster.provisioned.*.arn, aws_rds_cluster.serverless.*.arn))}"
}

output "cluster_id" {
  description = "The id of the Aurora Cluster"
  value       = "${join("", concat(aws_rds_cluster.provisioned.*.id, aws_rds_cluster.serverless.*.id))}"
}

output "cluster_endpoint" {
  description = "The endpoint of the Aurora Cluster"
  value       = "${join("", concat(aws_rds_cluster.provisioned.*.endpoint, aws_rds_cluster.serverless.*.endpoint))}"
}

output "cluster_reader_endpoint" {
  description = "The reader_endpoint of the Aurora Cluster"
  value       = "${join("", concat(aws_rds_cluster.provisioned.*.reader_endpoint, aws_rds_cluster.serverless.*.endpoint))}"
}

output "cluster_hosted_zone_id" {
  description = "The hosted_zone_id of the Aurora Cluster"
  value       = "${join(",", concat(aws_rds_cluster.provisioned.*.hosted_zone_id, aws_rds_cluster.serverless.*.hosted_zone_id))}"
}

# Aurora Instances
output "instance_arns" {
  description = "The ARNs of the Aurora Instances"
  value       = "${join(",", aws_rds_cluster_instance.provisioned.*.arn)}"
}

output "instance_ids" {
  description = "The IDs of the Aurora Instances"
  value       = "${join(",", aws_rds_cluster_instance.provisioned.*.id)}"
}

output "instance_endpoints" {
  description = "The Endpoints of the Aurora Instances"
  value       = "${join(",", aws_rds_cluster_instance.provisioned.*.endpoint)}"
}
