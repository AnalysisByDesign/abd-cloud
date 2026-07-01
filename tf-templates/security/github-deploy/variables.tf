# ============================================================================================
# GitHub Actions deploy role configuration
# ============================================================================================

variable "github_repo" {
  description = "GitHub repository in Org/Repo format permitted to assume this role (e.g. AnalysisByDesign/property-calculator)"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch permitted to assume this role"
  type        = string
  default     = "main"
}

variable "deploy_role_name" {
  description = "Name of the IAM role created for GitHub Actions deploys"
  type        = string
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
