# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

# S3
output "s3_id" {
  description = "The ID of the S3 bucket"
  value       = module.abd-s3.id
}

output "s3_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.abd-s3.arn
}

output "s3_bucket_domain_name" {
  description = "The domain name of the S3 bucket"
  value       = module.abd-s3.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket"
  value       = module.abd-s3.bucket_regional_domain_name
}

output "s3_hosted_zone_id" {
  description = "The R53 hosted zone id of the S3 bucket"
  value       = module.abd-s3.hosted_zone_id
}
