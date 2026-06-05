# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "ARN of the CloudTrail KMS key (only set when cloudtrail_hub = true)"
  value       = var.cloudtrail_hub ? aws_kms_key.cloudtrail[0].arn : null
}

