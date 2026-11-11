# ============================================================================================
# GitHub Actions deploy role configuration
# ============================================================================================

variable "deploy_roles" {
  description = "GitHub Actions deploy roles to create, keyed by a short app name. Each entry grants one GitHub repository (on one branch) the right to trigger SSM Run Command deploys."
  type = map(object({
    github_repo   = string                   # Org/Repo permitted to assume the role (e.g. AnalysisByDesign/property-calculator)
    github_branch = optional(string, "main") # Branch permitted to assume the role
    role_name     = string                   # Name of the IAM role created for GitHub Actions deploys
  }))
}

variable "ecr_push_roles" {
  description = "GitHub Actions ECR push roles to create, keyed by a short name. Each entry lets one GitHub repository (on one branch) push to the ECR repositories under its own prefixes."
  type = map(object({
    github_repo         = string                   # Org/Repo permitted to assume the role (e.g. AnalysisByDesign/abd-cloud-containers)
    github_branch       = optional(string, "main") # Branch permitted to assume the role
    role_name           = string                   # Name of the IAM role created for GitHub Actions pushes
    repository_prefixes = list(string)             # ECR namespaces the role may push to (e.g. ["abd"] for abd/*)
    # OIDC subject prefix when the repository uses GitHub's immutable subject format
    # (use_immutable_subject), e.g. repo:AnalysisByDesign@4380764/abd-cloud-containers@1452488510.
    # See: gh api repos/<org>/<repo>/actions/oidc/customization/sub (sub_claim_prefix).
    # Empty uses the name-only form, repo:<github_repo>.
    github_subject_prefix = optional(string, "")
  }))
  default = {}
}

variable "instance_tag_key" {
  description = "EC2 instance tag key used to scope SSM SendCommand access"
  type        = string
  default     = "Stack"
}

variable "instance_tag_value" {
  description = "EC2 instance tag value used to scope SSM SendCommand access"
  type        = string
}

# ============================================================================================
#                                      End of Variable Declarations
# ============================================================================================
