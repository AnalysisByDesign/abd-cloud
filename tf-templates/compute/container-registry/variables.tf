# ============================================================================================
# Container registry configuration
# ============================================================================================

variable "repositories" {
  description = "ECR repositories to create, keyed by repository name (e.g. abd/base). Lifecycle: expire untagged images after untagged_expiry_days and keep the newest keep_dated_images images with a tag matching dated_tag_pattern; or, for throwaway repositories, expire every image after expire_all_after_days."
  type = map(object({
    image_tag_mutability  = optional(string, "MUTABLE")
    scan_on_push          = optional(bool, true)
    untagged_expiry_days  = optional(number, 7)
    keep_dated_images     = optional(number, 30)
    dated_tag_pattern     = optional(string, "*-20*")
    expire_all_after_days = optional(number)
  }))
}

variable "pull_through_cache_prefix" {
  description = "Repository prefix for an ECR Public (public.ecr.aws) pull-through cache, e.g. ecr-public (empty for none)"
  type        = string
  default     = ""
}

variable "pull_through_cache_keep_images" {
  description = "Images to keep per repository created by the pull-through cache"
  type        = number
  default     = 10
}

variable "pull_policy_name" {
  description = "Name of a managed IAM policy allowing pulls from these repositories and the pull-through cache, for ECS execution roles (empty for none)"
  type        = string
  default     = ""
}

# ============================================================================================
#                                      End of Variable Declarations
# ============================================================================================
