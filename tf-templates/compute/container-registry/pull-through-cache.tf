# --------------------------------------------------------------------------------------------
# Pull-through cache for ECR Public (official Docker images under docker/library/*)
# Pull as <registry>/<prefix>/docker/library/<image>:<tag>; the first pull creates the
# repository from the creation template below. No upstream credentials are needed.
# Registry-wide, but scoped by its own prefix.
# --------------------------------------------------------------------------------------------

locals {
  pull_through_cache = var.pull_through_cache_prefix != "" ? 1 : 0
}

resource "aws_ecr_pull_through_cache_rule" "ecr_public" {
  count = local.pull_through_cache

  ecr_repository_prefix = var.pull_through_cache_prefix
  upstream_registry_url = "public.ecr.aws"
}

resource "aws_ecr_repository_creation_template" "pull_through_cache" {
  count = local.pull_through_cache

  prefix      = var.pull_through_cache_prefix
  description = "Settings for repositories created by the ECR Public pull-through cache"
  applied_for = ["PULL_THROUGH_CACHE"]

  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = format("Keep the newest %d images", var.pull_through_cache_keep_images)
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.pull_through_cache_keep_images
      }
      action = { type = "expire" }
    }]
  })
}
