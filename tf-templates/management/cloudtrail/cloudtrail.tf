# --------------------------------------------------------------------------------------------
# CloudTrail KMS key
# --------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "cloudtrail_kms" {
  statement {
    sid       = "EnableRootAccess"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "AllowCloudTrailDescribeKey"
    effect    = "Allow"
    actions   = ["kms:DescribeKey"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid       = "AllowCloudTrailEncrypt"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values = concat(
        ["arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"],
        [for acct in var.cloudtrail_allowed_accounts : "arn:aws:cloudtrail:*:${acct}:trail/*"]
      )
    }
  }

  dynamic "statement" {
    for_each = var.cloudtrail_allowed_accounts
    content {
      sid       = "AllowCrossAccountKeyAccess${statement.key}"
      effect    = "Allow"
      actions   = ["kms:DescribeKey"]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value}:root"]
      }
    }
  }
}

resource "aws_kms_key" "cloudtrail" {
  count               = var.cloudtrail_hub ? 1 : 0
  description         = "KMS key for CloudTrail log encryption — ${var.cloudtrail_name}"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudtrail_kms.json
  tags                = merge(local.common_tags, { Name = "${var.cloudtrail_name}-kms" })
}

resource "aws_kms_alias" "cloudtrail" {
  count         = var.cloudtrail_hub ? 1 : 0
  name          = "alias/${var.cloudtrail_name}"
  target_key_id = aws_kms_key.cloudtrail[0].key_id
}

# --------------------------------------------------------------------------------------------
# CloudTrail
# --------------------------------------------------------------------------------------------

resource "aws_cloudtrail" "this" {
  name                          = var.cloudtrail_name
  s3_bucket_name                = var.s3_name
  s3_key_prefix                 = ""
  include_global_service_events = true
  enable_logging                = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = var.cloudtrail_hub ? aws_kms_key.cloudtrail[0].arn : (var.cloudtrail_kms_key_arn != "" ? var.cloudtrail_kms_key_arn : null)

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
  tags       = merge(local.common_tags, tomap({ "Name" = format("%s", var.cloudtrail_name) }))
  depends_on = [module.cloudtrail-s3]
}
