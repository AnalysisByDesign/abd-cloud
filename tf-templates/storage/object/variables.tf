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
  type        = string
  default     = "private"
}

variable "s3_logging" {
  description = "Access logging configuration. Set to null to disable."
  type = object({
    target_bucket = string
    target_prefix = string
  })
  default = null
}

variable "s3_lifecycle_rule" {
  description = "A list of lifecycle rule objects to apply to the bucket"
  type        = list(any)
  default     = []
}

variable "s3_policy" {
  description = "An S3 policy to apply to the bucket"
  type        = string
  default     = ""
}

variable "s3_force_destroy" {
  description = "Forcibly destroy all objects if removing the bucket - be careful!"
  default     = false
}

variable "s3_acceleration_status" {
  description = "Transfer acceleration status. Set to 'Enabled' to enable, or leave empty to leave unconfigured."
  type        = string
  default     = ""
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
  type        = map(string)
  default     = {}
}

variable "files_folder" {
  description = "Folder containing sample files to load to the bucket"
  type        = string
  default     = ""
}

variable "s3_files" {
  description = "List of sample files to load to the bucket"
  type        = list(string)
  default     = []
}

variable "s3_files_tags" {
  description = "Additional tags for the sample S3 bucket objects"
  type        = map(string)
  default     = {}
}

variable "policy_folder" {
  description = "Folder containing policy templates to apply to the bucket"
  type        = string
  default     = "./files"
}

variable "policy_file" {
  description = "Policy template file to apply to the bucket"
  type        = string
  default     = "blank.tpl.json"
}
