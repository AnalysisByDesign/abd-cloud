# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

# Route53 Delegation Set
output "delegate_set_id" {
  description = "The ID of the delegate set"
  value       = "${module.r53_delegate.id}"
}

output "delegate_set_name_servers" {
  description = "The Name Servers of the delegate set"
  value       = "${module.r53_delegate.name_servers}"
}

# Route53 Public
output "public_zone_name" {
  value = "${local.public_search_domain}"
}

output "public_zone_id" {
  description = "The ID of the public zone"
  value       = "${module.r53_public.zone_id}"
}

output "public_zone_name_servers" {
  description = "The Name Servers of the public zone"
  value       = "${module.r53_public.name_servers}"
}
