output "registry_host" {
  description = "ECR registry host, for ECR_REGISTRY in consuming GitHub repositories"
  value       = format("%s.dkr.ecr.%s.amazonaws.com", data.aws_caller_identity.current.account_id, var.target_region)
}

output "repository_urls" {
  description = "Repository URLs, keyed by repository name"
  value       = { for name, repo in module.repository : name => repo.repository_url }
}

output "repository_arns" {
  description = "Repository ARNs, keyed by repository name"
  value       = { for name, repo in module.repository : name => repo.repository_arn }
}

output "pull_through_cache_prefix" {
  description = "Prefix for images pulled through the ECR Public cache, e.g. <registry_host>/<prefix>/docker/library/valkey:8 (null when disabled)"
  value       = local.pull_through_cache == 1 ? var.pull_through_cache_prefix : null
}

output "pull_policy_arn" {
  description = "Managed IAM policy ARN to attach to ECS execution roles (null when disabled)"
  value       = one(aws_iam_policy.pull[*].arn)
}
