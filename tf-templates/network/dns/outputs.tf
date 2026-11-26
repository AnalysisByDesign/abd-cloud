# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

output "domain_validation_options" {
  value = module.ssl_cert.domain_validation_options
}

output "zone_id" {
  description = "The ID of the public zone"
  value       = module.r53_public.zone_id
}

output "dns_challenge_user_name" {
  description = "The IAM user for the ACME DNS-01 challenge. Create the access key by hand with aws iam create-access-key"
  value       = join("", aws_iam_user.dns_challenge[*].name)
}

output "name_servers" {
  description = "The name servers to set at the registrar for this zone"
  value       = flatten(module.r53_delegate.name_servers)
}
