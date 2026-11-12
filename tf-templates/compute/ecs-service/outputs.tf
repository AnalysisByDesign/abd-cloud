# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

output "service_name" {
  description = "The ECS service's name"
  value       = module.service.name
}

output "task_definition_family" {
  description = "Task definition family; CI registers new revisions of it"
  value       = module.task.family
}

output "execution_role_arn" {
  description = "Execution role (CI must be allowed to pass it)"
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "Task role (CI must be allowed to pass it)"
  value       = aws_iam_role.task.arn
}

output "log_group_name" {
  description = "The service's log group"
  value       = module.log_group.names_of_groups[0]
}

output "target_group_arn" {
  description = "Target group (null without a load balancer)"
  value       = try(aws_lb_target_group.this[0].arn, null)
}

output "service_discovery_name" {
  description = "Cloud Map DNS name (null without service discovery)"
  value       = local.service_discovery ? format("%s.%s", aws_service_discovery_service.this[0].name, var.service_discovery_namespace) : null
}
