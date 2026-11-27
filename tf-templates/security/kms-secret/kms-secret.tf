# -----------------------------------------------------------------------------
# Secrets Manager secret, its dedicated KMS key, and the one role that uses it
# -----------------------------------------------------------------------------
# No aws_secretsmanager_secret_version here on purpose: the value is written
# once, outside Terraform, so it never reaches the state. The access role is
# the only principal the key policy lets use the key, and only through
# Secrets Manager, so other administrators in the account cannot read the
# value without first changing the key policy (which CloudTrail records).

locals {
  tags = merge(local.common_tags, var.extra_tags)

  secretsmanager_service = "secretsmanager.${var.target_region}.amazonaws.com"
}

# -----------------------------------------------------------------------------
# Access role
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "access_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.access_role_trusted_principals
    }

    dynamic "condition" {
      for_each = var.access_role_require_mfa ? [true] : []
      content {
        test     = "Bool"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["true"]
      }
    }
  }
}

resource "aws_iam_role" "access" {
  name                 = var.access_role_name
  description          = "Reads ${var.secret_name} from Secrets Manager"
  max_session_duration = var.access_role_max_session_duration
  assume_role_policy   = data.aws_iam_policy_document.access_trust.json

  tags = local.tags
}

# -----------------------------------------------------------------------------
# KMS key
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "key" {
  # The account root administers the key so it can never be locked out, but
  # gets no cryptographic actions: nobody decrypts with it through IAM alone.
  statement {
    sid    = "KeyAdministration"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.acct_target}:root"]
    }

    actions = [
      "kms:CancelKeyDeletion",
      "kms:Create*",
      "kms:Delete*",
      "kms:Describe*",
      "kms:Disable*",
      "kms:Enable*",
      "kms:Get*",
      "kms:List*",
      "kms:Put*",
      "kms:Revoke*",
      "kms:RotateKeyOnDemand",
      "kms:ScheduleKeyDeletion",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:Update*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "UseThroughSecretsManagerOnly"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.access.arn]
    }

    actions   = concat(["kms:Decrypt", "kms:DescribeKey"], var.allow_write ? ["kms:GenerateDataKey"] : [])
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = [local.secretsmanager_service]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.acct_target]
    }
  }

  # When a secret is created with (or moved to) this key, Secrets Manager
  # checks the caller can use it by calling GenerateDataKey and Decrypt with
  # encryption context SecretVersionId = RequestToValidateKeyAccess, and
  # discards the results. The Terraform role gets only those check calls:
  # real secret versions have a UUID SecretVersionId, so it still cannot
  # decrypt the value.
  statement {
    sid    = "TerraformKeyAccessCheck"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.acct_target}:role/${var.acct_target_role}"]
    }

    actions   = ["kms:GenerateDataKey", "kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = [local.secretsmanager_service]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:SecretVersionId"
      values   = ["RequestToValidateKeyAccess"]
    }
  }
}

resource "aws_kms_key" "secret" {
  description         = var.kms_description
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.key.json

  tags = local.tags
}

resource "aws_kms_alias" "secret" {
  name          = var.kms_alias
  target_key_id = aws_kms_key.secret.key_id
}

# -----------------------------------------------------------------------------
# Secret (no value, no rotation)
# -----------------------------------------------------------------------------
# Automatic rotation does not apply: the reason is recorded on the secret as
# the RotationExempt tag, from var.rotation_exemption_reason.

resource "aws_secretsmanager_secret" "this" {
  name                    = var.secret_name
  description             = var.secret_description
  kms_key_id              = aws_kms_key.secret.arn
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(local.tags, {
    RotationExempt = var.rotation_exemption_reason
  })
}

# -----------------------------------------------------------------------------
# Access role permissions: the one secret and the one key, HTTPS only
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "access" {
  statement {
    sid       = "ReadSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [aws_secretsmanager_secret.this.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }

  statement {
    sid       = "DecryptWithKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [aws_kms_key.secret.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }

  # Needed once, to write the value. Remove with allow_write = false.
  dynamic "statement" {
    for_each = var.allow_write ? [true] : []
    content {
      sid    = "InitialWrite"
      effect = "Allow"
      actions = [
        "secretsmanager:PutSecretValue",
        "kms:GenerateDataKey",
      ]
      resources = [
        aws_secretsmanager_secret.this.arn,
        aws_kms_key.secret.arn,
      ]

      condition {
        test     = "Bool"
        variable = "aws:SecureTransport"
        values   = ["true"]
      }
    }
  }
}

resource "aws_iam_role_policy" "access" {
  name   = "${var.access_role_name}-secret-access"
  role   = aws_iam_role.access.id
  policy = data.aws_iam_policy_document.access.json
}
