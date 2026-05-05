# --------------------------------------------------------------------------------------------
# Data Sources
# --------------------------------------------------------------------------------------------

locals {
  repository_lifecycle_policy = templatefile("${var.docker_repository_policy_folder}/${var.docker_repository_policy_file}", {})
}
