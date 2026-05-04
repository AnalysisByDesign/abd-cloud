# --------------------------------------------------------------------------------------------
# Docker repository
# --------------------------------------------------------------------------------------------

module "docker_repository" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//compute/docker-repository"

  required                   = var.docker_repository_required
  repository_name            = var.docker_repository_name
  repository_policy_document = data.aws_iam_policy_document.repository_policy.json

  repository_lifecycle_document = (var.docker_repository_lifecycle_policy != ""
    ? var.docker_repository_lifecycle_policy
  : data.template_file.repository_lifecycle_policy.rendered)
}
