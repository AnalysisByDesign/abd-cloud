# -----------------------------------------------------------------------------
# ECS Deploy Roles - one per GitHub repository that rolls out services
# -----------------------------------------------------------------------------
# Trusted like the ECR push roles, for one branch of one repository. Each role can
# register task definitions and update only its own services (WP-04 ruling 7). CI takes
# a family's latest revision, swaps the image digest, registers it and updates the
# service, so the role may also pass that service's execution and task roles to ECS.

data "aws_iam_policy_document" "ecs_deploy_trust" {
  for_each = var.ecs_deploy_roles

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
      values = [format("%s:ref:refs/heads/%s",
        each.value.github_subject_prefix != "" ? each.value.github_subject_prefix : "repo:${each.value.github_repo}",
      each.value.github_branch)]
    }
  }
}

data "aws_iam_policy_document" "ecs_deploy_permissions" {
  for_each = var.ecs_deploy_roles

  # Task definition reads and registration cannot be scoped to a family
  statement {
    sid    = "TaskDefinitions"
    effect = "Allow"
    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:TagResource",
    ]
    resources = ["*"]
  }

  # Roll out and watch its own services only
  statement {
    sid     = "OwnServices"
    effect  = "Allow"
    actions = ["ecs:DescribeServices", "ecs:UpdateService"]
    resources = [
      for svc in each.value.services :
      "arn:aws:ecs:${var.target_region}:${var.acct_target}:service/${each.value.cluster_name}/${svc}"
    ]
  }

  # Those services' execution and task roles, as named by the ecs-service template
  statement {
    sid     = "PassOwnServiceRoles"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = flatten([
      for svc in each.value.services : [
        "arn:aws:iam::${var.acct_target}:role/${each.value.role_name_prefix}-ecs-${svc}-execution",
        "arn:aws:iam::${var.acct_target}:role/${each.value.role_name_prefix}-ecs-${svc}-task",
      ]
    ])

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_deploy" {
  for_each = var.ecs_deploy_roles

  name               = each.value.role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_deploy_trust[each.key].json

  tags = merge(local.common_tags, {
    Purpose = "GitHub Actions ECS deploy role for ${each.value.github_repo}"
    Repo    = each.value.github_repo
  })
}

resource "aws_iam_role_policy" "ecs_deploy" {
  for_each = var.ecs_deploy_roles

  name   = "${each.value.role_name}-inline"
  role   = aws_iam_role.ecs_deploy[each.key].id
  policy = data.aws_iam_policy_document.ecs_deploy_permissions[each.key].json
}
