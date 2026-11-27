output "sync_role_arns" {
  value       = { for key, role in aws_iam_role.sync : key => role.arn }
  description = "Sync role ARNs, keyed by name. The role_arn in the pushing machine's AWS profile"
}

output "sync_user_names" {
  value       = { for key, user in aws_iam_user.sync : key => user.name }
  description = "IAM users that may assume each sync role, keyed by name. Create their access key by hand"
}
