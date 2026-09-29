# -----------------------------------------------------------------------------
# An optional IAM user for completing the ACME DNS-01 challenge in this zone
# -----------------------------------------------------------------------------
# Programmatic access only - no login profile is created.
# Deliberately absent: aws_iam_access_key - the secret would land in state.
# The key is created by hand afterwards:
#   aws iam create-access-key --user-name <dns_challenge_user_name>

resource "aws_iam_user" "dns_challenge" {
  count = var.dns_challenge_user_name != "" ? 1 : 0

  name = var.dns_challenge_user_name

  tags = merge(local.common_tags, {
    Purpose = "ACME DNS-01 challenge for ${local.public_search_domain}"
  })
}

data "aws_iam_policy_document" "dns_challenge" {
  count = var.dns_challenge_user_name != "" ? 1 : 0

  # Locate the zone by name - ListHostedZones cannot be resource-scoped
  statement {
    sid    = "DiscoverHostedZones"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
    ]
    resources = ["*"]
  }

  # Wait for the challenge record to propagate - change IDs are not known in advance
  statement {
    sid       = "PollChangeStatus"
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }

  # All write capability is confined to this one zone
  statement {
    sid    = "ManageDeveloperZoneRecords"
    effect = "Allow"
    actions = [
      "route53:ListResourceRecordSets",
      "route53:ChangeResourceRecordSets",
    ]
    resources = ["arn:aws:route53:::hostedzone/${module.r53_public.zone_id}"]
  }
}

resource "aws_iam_user_policy" "dns_challenge" {
  count = var.dns_challenge_user_name != "" ? 1 : 0

  name   = "${var.dns_challenge_user_name}-inline"
  user   = aws_iam_user.dns_challenge[0].name
  policy = data.aws_iam_policy_document.dns_challenge[0].json
}
