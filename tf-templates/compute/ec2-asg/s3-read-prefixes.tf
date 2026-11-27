# -----------------------------------------------------------------------------
# Read-only access to selected S3 prefixes (opt-in via var.s3_read_prefixes)
# -----------------------------------------------------------------------------
# Kept apart from the templated instance policy so that turning it on touches
# nothing else. Each entry is "<bucket>/<prefix>".

locals {
  s3_read_prefixes = {
    for entry in var.s3_read_prefixes : entry => {
      bucket = split("/", entry)[0]
      prefix = join("/", slice(split("/", entry), 1, length(split("/", entry))))
    }
  }
}

data "aws_iam_policy_document" "s3_read_prefixes" {
  count = length(var.s3_read_prefixes) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = local.s3_read_prefixes
    content {
      sid       = "List${replace(title(replace(statement.key, "/[^A-Za-z0-9]+/", " ")), " ", "")}"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = ["arn:aws:s3:::${statement.value.bucket}"]

      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = [statement.value.prefix, "${statement.value.prefix}/*"]
      }
    }
  }

  statement {
    sid       = "GetObjectsUnderPrefixes"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [for p in values(local.s3_read_prefixes) : "arn:aws:s3:::${p.bucket}/${p.prefix}/*"]
  }
}

resource "aws_iam_role_policy" "s3_read_prefixes" {
  count = length(var.s3_read_prefixes) > 0 ? 1 : 0

  name   = "s3-read-prefixes"
  role   = module.ec2_asg_role.names
  policy = data.aws_iam_policy_document.s3_read_prefixes[0].json
}
