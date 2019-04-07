# ============================================================================================
#                                      Common
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "acct_apex" {
  description = "Account where Apex domain can be found"
  type        = "string"
}

# ============================================================================================
#                                      Remote access policy
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "acct_auth" {
  description = "Authentication account number"
  type        = "string"
}

# Optional -----------------------------------------------------------------------------------
variable "remote_automation_hub" {
  description = "Is this account the remote automation hub for automation"
  default     = false
}

variable "remote_access_name" {
  description = "The IAM policy describing cross account role assumption"
  type        = "string"
  default     = "automation"
}

variable "remote_access_description" {
  description = "The IAM policy describing cross account role assumption"
  type        = "string"
  default     = "Role used by automation"
}

# ============================================================================================
#                                    Password Policy Rules
# ============================================================================================

# Required -----------------------------------------------------------------------------------

# NONE

# Optional -----------------------------------------------------------------------------------

variable "minimum_password_length" {
  default = 10
}

variable "password_reuse_prevention" {
  default = 5
}

variable "require_lowercase_characters" {
  default = true
}

variable "require_uppercase_characters" {
  default = true
}

variable "require_numbers" {
  default = true
}

variable "require_symbols" {
  default = true
}

variable "allow_users_to_change_password" {
  default = true
}

variable "hard_expiry" {
  default = true
}

# ============================================================================================
#                                      Route53
# ============================================================================================

# Required -----------------------------------------------------------------------------------

# None

# Optional -----------------------------------------------------------------------------------

variable "delegate_set_name" {
  description = "A reference name for the delegate set"
  type        = "string"
  default     = ""
}

variable "delegation_enabled" {
  description = "Do we need this sub-domain delegated from our apex domain"
  default     = false
}

variable "use_existing_zones" {
  description = "Re-use existing public and private zones"
  default     = false
}

variable "r53_tags" {
  description = "Additional tags for the Route53 Entries"
  type        = "map"

  default = {
    "Component" = "account"
  }
}

# ============================================================================================
#                                      NewRelic Monitoring
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "newrelic_required" {
  description = "Do we need to have NewRelic monitor the infrastructure for this account"
  default     = false
}

# Optional -----------------------------------------------------------------------------------

#None

# ============================================================================================
#                                      Docker Repository
# ============================================================================================

# Required -----------------------------------------------------------------------------------

# None

# Optional -----------------------------------------------------------------------------------

variable "docker_repository_required" {
  description = "Defines whether we need to build a Docker repository in this account"
  default     = false
}

variable "docker_repository_name" {
  description = "Name of ECR repository"
  type        = "string"
  default     = "docker-repo"
}

variable "docker_repository_lifecycle_policy" {
  description = "Lifecycle policies for ECR component"
  type        = "string"
  default     = ""
}

variable "docker_repository_policy_folder" {
  description = "Folder containing policy templates to apply to the bucket"
  type        = "string"
  default     = "./files"
}

variable "docker_repository_policy_file" {
  description = "Policy template file to apply to the bucket"
  type        = "string"
  default     = "docker-repo-14-day-expire.tpl.json"
}

# ============================================================================================
#                                   CloudWatch Groups
# ============================================================================================

variable "cloudwatch_tags" {
  description = "Additional tags for CloudWatch"
  type        = "map"

  default = {
    "Component" = "cloudwatch"
  }
}

variable "cloudwatch_loggroup_names" {
  description = "Log group names for cloudwatch"
  type        = "list"
  default     = ["infra", "web", "app"]
}

# ============================================================================================
#                                      End of Variable Declarations
# ============================================================================================

