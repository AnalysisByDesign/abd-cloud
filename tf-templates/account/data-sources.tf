# --------------------------------------------------------------------------------------------
# Data Sources
# --------------------------------------------------------------------------------------------

data "template_file" "repository_lifecycle_policy" {
  template = file("${var.docker_repository_policy_folder}/${var.docker_repository_policy_file}")
}
