# --------------------------------------------------------------------------------------------
# Prepare the IAM policy documents
# --------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "rds_enhanced" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "newrelic" {
  statement {
    actions = ["sts:AssumeRole"]

    # Only allow remote access by NewRelic root account
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::754728514883:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["1745111"]
    }
  }
}

data "aws_iam_policy_document" "repository_policy" {
  statement {
    sid    = "EcrRepositoryPolicy"
    effect = "Allow"

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }

    actions = ["ecr:*"]
  }
}
