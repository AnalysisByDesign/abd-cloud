# -----------------------------------------------------------------------------
# ECR Push Roles - one per GitHub repository that builds images
# -----------------------------------------------------------------------------
# Trusted through the same OIDC provider as the deploy roles, for one branch of
# one repository. Each role can push only to its own namespaces
# (repository/<prefix>/*), so an images repository cannot overwrite another
# repository's images. Optionally, read access to named S3 prefixes for build
# inputs (s3_read_prefixes, kms_decrypt_key_arns).

data "aws_iam_policy_document" "ecr_push_trust" {
  for_each = var.ecr_push_roles

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

data "aws_iam_policy_document" "ecr_push_permissions" {
  for_each = var.ecr_push_roles

  # Registry login - GetAuthorizationToken cannot be resource-scoped
  statement {
    sid       = "RegistryLogin"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Push (and read back) images in this repository's own namespaces only
  statement {
    sid    = "PushOwnNamespaces"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [
      for prefix in each.value.repository_prefixes :
      "arn:aws:ecr:${var.target_region}:${var.acct_target}:repository/${prefix}/*"
    ]
  }

  # Build inputs from S3 (read only), when the repository has any
  dynamic "statement" {
    for_each = length(each.value.s3_read_prefixes) > 0 ? [1] : []
    content {
      sid       = "ReadBuildInputs"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = [for p in each.value.s3_read_prefixes : "arn:aws:s3:::${p}*"]
    }
  }

  dynamic "statement" {
    for_each = length(each.value.kms_decrypt_key_arns) > 0 ? [1] : []
    content {
      sid       = "DecryptBuildInputs"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = each.value.kms_decrypt_key_arns

      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["s3.${var.target_region}.amazonaws.com"]
      }
    }
  }
}

resource "aws_iam_role" "ecr_push" {
  for_each = var.ecr_push_roles

  name               = each.value.role_name
  assume_role_policy = data.aws_iam_policy_document.ecr_push_trust[each.key].json

  tags = merge(local.common_tags, {
    Purpose = "GitHub Actions ECR push role for ${each.value.github_repo}"
    Repo    = each.value.github_repo
  })
}

resource "aws_iam_role_policy" "ecr_push" {
  for_each = var.ecr_push_roles

  name   = "${each.value.role_name}-inline"
  role   = aws_iam_role.ecr_push[each.key].id
  policy = data.aws_iam_policy_document.ecr_push_permissions[each.key].json
}
