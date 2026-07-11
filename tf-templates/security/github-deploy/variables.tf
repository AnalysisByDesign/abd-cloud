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
