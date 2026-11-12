# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

output "cluster_name" {
  description = "The ECS cluster's name"
  value       = module.ecs-cluster.cluster_name
}

output "cluster_arn" {
  description = "The ECS cluster's ARN"
  value       = module.ecs-cluster.cluster_arn
}

output "capacity_provider_names" {
  description = "Capacity providers created so far (one per host ASG that exists)"
  value       = module.ecs-cluster.capacity_provider_names
}

output "service_discovery_namespace_id" {
  description = "The Cloud Map namespace ID (null when there is none)"
  value       = try(aws_service_discovery_private_dns_namespace.this[0].id, null)
}
