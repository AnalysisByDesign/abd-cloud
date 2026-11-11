output "github_deploy_role_arns" {
  value       = { for key, role in aws_iam_role.deploy : key => role.arn }
  description = "IAM role ARNs for GitHub Actions deploys, keyed by app name. Set as role-to-assume in each repo's .github/workflows/deploy.yml"
}

output "github_ecr_push_role_arns" {
  value       = { for key, role in aws_iam_role.ecr_push : key => role.arn }
  description = "IAM role ARNs for GitHub Actions ECR pushes, keyed by name. Set as ECR_PUSH_ROLE_ARN in the image repository"
}
