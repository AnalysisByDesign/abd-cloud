# --------------------------------------------------------------------------------------------
# ECR repositories, one module call per entry in var.repositories
# --------------------------------------------------------------------------------------------

locals {
  lifecycle_documents = {
    # Each branch is encoded separately: the two rule lists have different shapes
    for name, repo in var.repositories : name => repo.expire_all_after_days != null ? jsonencode({
      rules = [
        {
          rulePriority = 1
          description  = format("Expire every image after %d days", repo.expire_all_after_days)
          selection = {
            tagStatus   = "any"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = repo.expire_all_after_days
          }
          action = { type = "expire" }
        }
      ]
      }) : jsonencode({
      rules = [
        {
          rulePriority = 1
          description  = format("Expire untagged images after %d days", repo.untagged_expiry_days)
          selection = {
            tagStatus   = "untagged"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = repo.untagged_expiry_days
          }
          action = { type = "expire" }
        },
        {
          rulePriority = 2
          description  = format("Keep the newest %d dated images", repo.keep_dated_images)
          selection = {
            tagStatus      = "tagged"
            tagPatternList = [repo.dated_tag_pattern]
            countType      = "imageCountMoreThan"
            countNumber    = repo.keep_dated_images
          }
          action = { type = "expire" }
        },
      ]
    })
  }
}

module "repository" {
  source   = "../../../../abd-cloud-modules/compute/docker-repository"
  for_each = var.repositories

  required        = true
  repository_name = each.key

  image_tag_mutability = each.value.image_tag_mutability
  scan_on_push         = each.value.scan_on_push
  encryption_type      = "AES256"

  repository_lifecycle_document = local.lifecycle_documents[each.key]

  tags = local.common_tags
}
