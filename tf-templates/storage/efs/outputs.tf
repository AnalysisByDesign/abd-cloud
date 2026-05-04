# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

# EFS
output "efs_id" {
  description = "The ID of the EFS volume"
  value       = module.efs.id
}

output "efs_kms_key_id" {
  description = "The KMS key ID of the EFS volume"
  value       = module.efs.kms_key_id
}

output "efs_dns_name" {
  description = "The DNS name of the EFS volume"
  value       = module.efs.dns_name
}
