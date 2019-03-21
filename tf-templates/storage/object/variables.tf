# --------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# --------------------------------------------------------------------------------------------

# ============================================================================================
#                                      S3 Bucket
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "s3_name" {
  description = "The name of the S3 bucket"
}

# Optional -----------------------------------------------------------------------------------

variable "s3_acl" {
  description = "The canned ACL to apply"
  type        = "string"
  default     = "private"
}

variable "s3_logging" {
  description = "Logging configuration of the bucket"
  type        = "list"
  default     = []
}

variable "s3_lifecycle_rule" {
  description = "A list of lifecycle_rule maps to apply to the bucket"
  type        = "list"
  default     = []
}

variable "s3_policy" {
  description = "An S3 policy to apply to the bucket"
  type        = "string"
  default     = ""
}

variable "s3_force_destroy" {
  description = "Forcibly destroy all objects if removing the bucket - be careful!"
  default     = false
}

variable "s3_acceleration_status" {
  description = "Acceleration status of the bucket"
  type        = "string"
  default     = "Suspended"
}

variable "s3_enable_versioning" {
  description = "Enable object versioning"
  default     = false
}

variable "s3_enable_mfa_delete" {
  description = "Require an MFA device to delete objects"
  default     = false
}

variable "s3_tags" {
  description = "Additional tags for the S3 bucket"
  type        = "map"
  default     = {}
}

variable "files_folder" {
  description = "Folder containing sample files to load to the bucket"
  type        = "string"
  default     = ""
}

variable "s3_files" {
  description = "List of sample files to load to the bucket"
  type        = "list"
  default     = []
}

variable "s3_files_tags" {
  description = "Additional tags for the sample S3 bucket objects"
  type        = "map"
  default     = {}
}

variable "policy_folder" {
  description = "Folder containing policy templates to apply to the bucket"
  type        = "string"
  default     = "../../../tf-assets/policies/s3"
}

variable "policy_file" {
  description = "Policy template file to apply to the bucket"
  type        = "string"
  default     = "blank.json.tpl"
}
