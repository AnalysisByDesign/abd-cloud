# --------------------------------------------------------------------------------------------
# Managed pull policy for ECS execution roles (attached by the ECS cluster work, WP-04)
# Covers every namespace in var.repositories (e.g. abd/*) and the pull-through cache, whose
# first pull of an image creates its repository.
# --------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  pull_policy = var.pull_policy_name != "" ? 1 : 0

  repository_namespaces = distinct([for name in keys(var.repositories) : split("/", name)[0]])
  repository_arn_prefix = format("arn:aws:ecr:%s:%s:repository", var.target_region, data.aws_caller_identity.current.account_id)
}

data "aws_iam_policy_document" "pull" {
  count = local.pull_policy

  statement {
    sid       = "RegistryLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PullImages"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = concat(
      [for ns in local.repository_namespaces : format("%s/%s/*", local.repository_arn_prefix, ns)],
      local.pull_through_cache == 1 ? [format("%s/%s/*", local.repository_arn_prefix, var.pull_through_cache_prefix)] : [],
    )
  }

  dynamic "statement" {
    for_each = local.pull_through_cache == 1 ? [1] : []
    content {
      sid = "PullThroughCacheFirstPull"
      actions = [
        "ecr:BatchImportUpstreamImage",
        "ecr:CreateRepository",
      ]
      resources = [format("%s/%s/*", local.repository_arn_prefix, var.pull_through_cache_prefix)]
    }
  }
}

resource "aws_iam_policy" "pull" {
  count = local.pull_policy

  name        = var.pull_policy_name
  description = "Pull images from the ECR repositories and pull-through cache in this account"
  policy      = data.aws_iam_policy_document.pull[0].json

  tags = local.common_tags
}
