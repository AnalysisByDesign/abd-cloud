# ============================================================================================
#                                      Connectivity
# ============================================================================================

# --------------------------------------------------------------------------------------------
# Accepter VPC Data Source Configurations
# --------------------------------------------------------------------------------------------

variable "accepter_vpc_cidr" {
  description = "The VPC CIDR range to make the peering link to"
  type        = "string"
  default     = ""
}

variable "accepter_vpc_id" {
  description = "The VPC id range to make the peering link to"
  type        = "string"
  default     = ""
}

# --------------------------------------------------------------------------------------------
# Routing overrides if required
# --------------------------------------------------------------------------------------------

variable "requester_cidr_override" {
  description = "Optional CIDR range to forward through peering to the requester"
  type        = "string"
  default     = ""
}

variable "accepter_cidr_override" {
  description = "Optional CIDR range to forward through peering to the accepter"
  type        = "string"
  default     = ""
}

# ============================================================================================
#                                      End of Variable Declarations
# ============================================================================================

