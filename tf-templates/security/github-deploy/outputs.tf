output "github_deploy_role_arn" {
  value       = aws_iam_role.deploy.arn
  description = "IAM role ARN for GitHub Actions deploys. Set as role-to-assume in .github/workflows/deploy.yml"
}
