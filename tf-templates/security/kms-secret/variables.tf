# ============================================================================================
# Secrets Manager secret with a dedicated KMS key and access role
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "kms_alias" {
  description = "Alias for the dedicated KMS key, including the alias/ prefix (e.g. alias/tulox-kiosk-signing)"
  type        = string
}

variable "kms_description" {
  description = "Description of the dedicated KMS key"
  type        = string
}

variable "secret_name" {
  description = "Name of the Secrets Manager secret (e.g. tulox/kiosk/android-upload-key)"
  type        = string
}

variable "secret_description" {
  description = "Description of the Secrets Manager secret"
  type        = string
}

variable "rotation_exemption_reason" {
  description = "Why automatic rotation does not apply to this secret. Recorded on the secret as the RotationExempt tag (tag value characters only: letters, numbers, spaces and _ . : / = + - @)"
  type        = string
}

variable "access_role_name" {
  description = "Name of the IAM role that reads (and, while allow_write is true, writes) the secret"
  type        = string
}

variable "access_role_trusted_principals" {
  description = "IAM principal ARNs allowed to assume the access role"
  type        = list(string)
}

# Optional -----------------------------------------------------------------------------------

variable "recovery_window_in_days" {
  description = "Days Secrets Manager keeps the secret recoverable after deletion (7 to 30)"
  type        = number
  default     = 30
}

variable "access_role_require_mfa" {
  description = "Require MFA (aws:MultiFactorAuthPresent) to assume the access role"
  type        = bool
  default     = true
}

variable "access_role_max_session_duration" {
  description = "Maximum session duration of the access role, in seconds"
  type        = number
  default     = 3600
}

variable "allow_write" {
  description = "Grant the access role secretsmanager:PutSecretValue and kms:GenerateDataKey. Needed only to write the value; set false and apply again once it is written"
  type        = bool
  default     = true
}

variable "extra_tags" {
  description = "Tags added to every resource on top of the common tags"
  type        = map(string)
  default     = {}
}
