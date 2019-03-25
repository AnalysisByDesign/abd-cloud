# --------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# --------------------------------------------------------------------------------------------

# ============================================================================================
#                                      CloudTrail
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "cloudtrail_name" {
  description = "The name of the CloudTrail configuration"
  type        = "string"
}

# Optional -----------------------------------------------------------------------------------

variable "cloudtrail_hub" {
  description = "Is this the CloudTrail central hub"
  default     = false
}

# ============================================================================================
#                                      S3 Bucket
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "s3_name" {
  description = "The name of the S3 bucket to hold the cloud-trail logs"
  type        = "string"
}

# Optional -----------------------------------------------------------------------------------

variable "s3_lifecycle_rule" {
  description = "A list of lifecycle_rule maps to apply to the bucket"
  type        = "list"
  default     = []
}

variable "s3_tags" {
  description = "Additional tags for the S3 bucket"
  type        = "map"
  default     = {}
}
