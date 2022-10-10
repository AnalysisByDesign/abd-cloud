# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

# Route53 Delegation Set
output "delegate_set_id" {
  description = "The ID of the delegate set"
  value       = module.r53_delegate.id
}

output "delegate_set_name_servers" {
  description = "The Name Servers of the delegate set"
  value       = module.r53_delegate.name_servers
}

# Route53 Public
output "public_zone_name" {
  value = local.public_search_domain
}

output "public_zone_id" {
  description = "The ID of the public zone"
  value       = module.r53_public.zone_id
}

output "public_zone_name_servers" {
  description = "The Name Servers of the public zone"
  value       = module.r53_public.name_servers
}

# --------------------------------------------------------------------------------------------
# Docker repository
# --------------------------------------------------------------------------------------------

output "docker_repository_arn" {
  value = module.docker_repository.repository_arn
}

output "docker_repository_url" {
  value = module.docker_repository.repository_url
}

output "docker_registry_id" {
  value = module.docker_repository.registry_id
}

output "docker_repository_name" {
  value = module.docker_repository.repository_name
}
