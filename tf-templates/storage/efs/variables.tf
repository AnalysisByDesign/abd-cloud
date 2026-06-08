# --------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# --------------------------------------------------------------------------------------------

# ============================================================================================
#                                      EFS
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "name" {
  description = "The name of the EFS volume"
  type        = string
}

# Optional -----------------------------------------------------------------------------------

variable "performance_mode" {
  description = "The performance mode of the EFS filesystem"
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "Throughput mode for the EFS filesystem (bursting, provisioned, elastic)"
  type        = string
  default     = "bursting"
}

variable "lifecycle_policy_transition_to_ia" {
  description = "How long until files transition to Infrequent Access storage (e.g. AFTER_30_DAYS)"
  type        = string
  default     = null
}

variable "lifecycle_policy_transition_to_archive" {
  description = "How long until files transition to Archive storage (e.g. AFTER_90_DAYS)"
  type        = string
  default     = null
}

variable "lifecycle_policy_transition_to_primary_storage_class" {
  description = "When to move files back to primary storage on access (AFTER_1_ACCESS)"
  type        = string
  default     = null
}

variable "encrypted" {
  description = "Create an encrypted data volume"
  default     = true
}

variable "kms_key_id" {
  description = "Create an encrypted data volume"
  type        = string
  default     = ""
}

variable "efs_tags" {
  description = "Additional tags for the EFS volume"
  type        = map(string)

  default = {
    "Component" = "storage"
  }
}

# ============================================================================================
#                                   Mount Targets
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "private_db_subnets" {
  description = "A list of subnet CIDR ranges to be used for this EFS"
  type        = list(string)
}

# Optional -----------------------------------------------------------------------------------

