# --------------------------------------------------------------------------------------------
# Connection details for the accepter side of the peering link
# --------------------------------------------------------------------------------------------

# Required -----------------------------------------------------------------------------------

variable "accepter_target" {
  description = "Accepter AWS account to receive peering request"
  type        = "string"
}

# Optional -----------------------------------------------------------------------------------

variable "accepter_target_role" {
  description = "Role in accepter account to use to approve peering request"
  type        = "string"
  default     = ""
}

variable "accepter_region" {
  description = "The region of the accepter VPC"
  type        = "string"
  default     = ""
}

# --------------------------------------------------------------------------------------------

provider "aws" {
  alias = "accepter"

  version = "~> 1.48"

  region = "${var.accepter_region != "" ? var.accepter_region : var.target_region}"

  assume_role {
    role_arn = "arn:aws:iam::${var.accepter_target}:role/${var.accepter_target_role == "" 
                  ? "terraform" 
                  : var.accepter_target_role}"
  }
}
