# --------------------------------------------------------------------------------------------
# IAM Roles
# --------------------------------------------------------------------------------------------

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

# --------------------------------------------------------------------------------------------
# RDS Enhanced Monitoring Role Enabled at account level
module "rds_monitoring_role" {
  source = "../../../abd-cloud-modules/security/iam-role"

  roles = [{
    name               = "rds-enhanced-monitoring"
    description        = "Allows RDS enhanced monitoring"
    assume_role_policy = "${data.aws_iam_policy_document.rds_enhanced.json}"
    policy_arn         = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  }]
}

# --------------------------------------------------------------------------------------------
# Administrator cross-account role access
module "remote_admins" {
  source = "../../../abd-cloud-modules/security/iam-role"

  roles = [{
    name               = "admins"
    description        = "admins"
    path               = "/"
    assume_role_policy = "${data.aws_iam_policy_document.remote_assume_role_policy.json}"
    policy_arn         = "arn:aws:iam::aws:policy/AdministratorAccess"
  }]
}

# ============================================================================================
#                           GitHub Actions OIDC (bootstrap — run manually first)
# ============================================================================================
#
# Bootstrap sequence:
#   1. Run: tf-run.sh apply abd-global/account-global  (with local AWS credentials)
#   2. Add the resulting role ARN to GitHub org variable: AWS_MANAGEMENT_ACCOUNT_ID
#   3. All subsequent infrastructure changes can then use GitHub Actions workflows
# ============================================================================================

resource "aws_iam_openid_connect_provider" "github" {
  count = var.github_org != "" ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

resource "aws_iam_role" "github_actions_terraform" {
  count = var.github_org != "" ? 1 : 0

  name        = var.github_actions_role_name
  description = "Assumed by GitHub Actions via OIDC to run Terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github[0].arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/*:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  count = var.github_org != "" ? 1 : 0

  role       = aws_iam_role.github_actions_terraform[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
