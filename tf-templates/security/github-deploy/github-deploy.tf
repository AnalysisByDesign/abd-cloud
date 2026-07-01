# -----------------------------------------------------------------------------
# GitHub Actions OIDC Provider
# -----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Deploy Role
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "deploy_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name               = var.deploy_role_name
  assume_role_policy = data.aws_iam_policy_document.deploy_trust.json

  tags = merge(local.common_tags, {
    Purpose = "GitHub Actions deploy role for ${var.github_repo}"
    Repo    = var.github_repo
  })
}

# -----------------------------------------------------------------------------
# Deploy Role Inline Permissions
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "deploy_permissions" {
  # Discover the running instance — DescribeInstances cannot be resource-scoped
  statement {
    sid       = "DescribeInstances"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }

  # Send a shell command to instances carrying the expected tag
  statement {
    sid     = "SSMSendCommand"
    effect  = "Allow"
    actions = ["ssm:SendCommand"]

    resources = [
      "arn:aws:ec2:${var.target_region}:${var.acct_target}:instance/*",
      "arn:aws:ssm:${var.target_region}::document/AWS-RunShellScript",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/${var.instance_tag_key}"
      values   = [var.instance_tag_value]
    }
  }

  # Read command output — needed to wait for completion and surface errors
  statement {
    sid    = "SSMReadResults"
    effect = "Allow"
    actions = [
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "${var.deploy_role_name}-inline"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy_permissions.json
}
