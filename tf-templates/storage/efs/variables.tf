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
  type        = "string"
}

# Optional -----------------------------------------------------------------------------------

variable "performance_mode" {
  description = "The performance mode of the EFS filesystem"
  type        = "string"
  default     = "generalPurpose"
}

variable "encrypted" {
  description = "Create an encrypted data volume"
  default     = true
}

variable "kms_key_id" {
  description = "Create an encrypted data volume"
  type        = "string"
  default     = ""
}

variable "efs_tags" {
  description = "Additional tags for the EFS volume"
  type        = "map"

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
  type        = "list"
}

# Optional -----------------------------------------------------------------------------------

