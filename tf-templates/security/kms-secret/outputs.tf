output "secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.this.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key that encrypts the secret"
  value       = aws_kms_key.secret.arn
}

output "kms_alias" {
  description = "Alias of the KMS key"
  value       = aws_kms_alias.secret.name
}

output "access_role_arn" {
  description = "ARN of the role the secret access policy is attached to. The role_arn of the AWS CLI profile used to read the secret"
  value       = aws_iam_role.access.arn
}

output "write_enabled" {
  description = "Whether the access role can still write the secret (allow_write)"
  value       = var.allow_write
}
