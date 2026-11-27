# ============================================================================================
# S3 prefix sync roles
# ============================================================================================

variable "sync_roles" {
  description = "Roles that push content into one S3 prefix, keyed by a short name. Each role may list the prefix and read and write objects under it, and nothing else: no delete or version action is granted, and object deletes and lifecycle changes on the bucket are explicitly denied. An optional IAM user can assume the role from outside AWS; its access key is created by hand, never by Terraform, so the secret stays out of state."
  type = map(object({
    role_name            = string                 # Name of the IAM role
    bucket               = string                 # Bucket name (not ARN)
    prefix               = string                 # Key prefix without slashes, e.g. marketing-images
    kms_key_arn          = optional(string, "")   # Customer managed key that encrypts the bucket. Empty for SSE-S3
    max_session_duration = optional(number, 3600) # Seconds
    # IAM user whose only permission is sts:AssumeRole on this role, for a machine outside AWS.
    # Empty creates no user, and the role then trusts nobody until a trust route is added.
    user_name = optional(string, "")
  }))
  default = {}
}
