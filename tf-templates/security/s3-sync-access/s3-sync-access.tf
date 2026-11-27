# -----------------------------------------------------------------------------
# S3 prefix sync roles
# -----------------------------------------------------------------------------
# One role per entry in var.sync_roles, able to list one prefix of one bucket
# and get or put the objects under it. Pushes are additive by design: there is
# no delete or version permission, and an explicit deny keeps it that way even
# if a broader policy is attached to the role later.

locals {
  sync_users = { for key, cfg in var.sync_roles : key => cfg if cfg.user_name != "" }
}

# -----------------------------------------------------------------------------
# Optional IAM user per role (for a machine outside AWS)
# -----------------------------------------------------------------------------
# No aws_iam_access_key here on purpose: its secret would be written to the
# Terraform state. The key is created by hand and handed straight to the
# machine that uses it.

resource "aws_iam_user" "sync" {
  for_each = local.sync_users

  name = each.value.user_name

  tags = merge(local.common_tags, {
    Purpose = "Assumes ${each.value.role_name} only"
  })
}

data "aws_iam_policy_document" "sync_user" {
  for_each = local.sync_users

  statement {
    sid       = "AssumeSyncRoleOnly"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.sync[each.key].arn]
  }
}

resource "aws_iam_user_policy" "sync" {
  for_each = local.sync_users

  name   = "${each.value.user_name}-assume-${each.value.role_name}"
  user   = aws_iam_user.sync[each.key].name
  policy = data.aws_iam_policy_document.sync_user[each.key].json
}

# -----------------------------------------------------------------------------
# Roles
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "sync_trust" {
  for_each = var.sync_roles

  # With no user the role trusts the account root, which on its own lets no
  # one in: a principal still needs an identity policy allowing the assume.
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [each.value.user_name != ""
        ? aws_iam_user.sync[each.key].arn
      : "arn:aws:iam::${var.acct_target}:root"]
    }
  }
}

resource "aws_iam_role" "sync" {
  for_each = var.sync_roles

  name                 = each.value.role_name
  description          = "Push into s3://${each.value.bucket}/${each.value.prefix}/ - no delete"
  max_session_duration = each.value.max_session_duration
  assume_role_policy   = data.aws_iam_policy_document.sync_trust[each.key].json

  tags = merge(local.common_tags, {
    Purpose = "Push into s3://${each.value.bucket}/${each.value.prefix}/"
  })
}

data "aws_iam_policy_document" "sync_permissions" {
  for_each = var.sync_roles

  statement {
    sid       = "ListPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${each.value.bucket}"]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [each.value.prefix, "${each.value.prefix}/*"]
    }
  }

  statement {
    sid       = "GetPutObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${each.value.bucket}/${each.value.prefix}/*"]
  }

  dynamic "statement" {
    for_each = each.value.kms_key_arn != "" ? [each.value.kms_key_arn] : []
    content {
      sid       = "BucketKey"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = [statement.value]
    }
  }

  # Belt and braces: nothing above allows these, and this keeps it so.
  statement {
    sid    = "NeverDelete"
    effect = "Deny"
    actions = [
      "s3:DeleteObject*",
      "s3:PutLifecycleConfiguration",
      "s3:PutBucketVersioning",
    ]
    resources = [
      "arn:aws:s3:::${each.value.bucket}",
      "arn:aws:s3:::${each.value.bucket}/*",
    ]
  }
}

resource "aws_iam_role_policy" "sync" {
  for_each = var.sync_roles

  name   = "${each.value.role_name}-inline"
  role   = aws_iam_role.sync[each.key].id
  policy = data.aws_iam_policy_document.sync_permissions[each.key].json
}
