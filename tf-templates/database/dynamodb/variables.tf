# --------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# --------------------------------------------------------------------------------------------

# Required -----------------------------------------------------------------------------------

# DynamoDB Table Name
variable "name" {
  description = "Name of DynamoDB table"
  type        = string
}

# Optional -----------------------------------------------------------------------------------

variable "dynamodb_tags" {
  description = "Additional tags for the DynamoDB table"
  type        = map(string)

  default = {
    "Component" = "dynamodb"
  }
}
