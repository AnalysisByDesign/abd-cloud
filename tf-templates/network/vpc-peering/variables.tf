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

variable "public_requester_cidr_override" {
  description = "Optional CIDR range to forward through peering to the requester from public subnets"
  type        = "string"
  default     = ""
}

variable "public_accepter_cidr_override" {
  description = "Optional CIDR range to forward through peering to the accepter from public subnets"
  type        = "string"
  default     = ""
}

variable "private_requester_cidr_override" {
  description = "Optional CIDR range to forward through peering to the requester from private subnets"
  type        = "string"
  default     = ""
}

variable "private_accepter_cidr_override" {
  description = "Optional CIDR range to forward through peering to the accepter from private subnets"
  type        = "string"
  default     = ""
}

# ============================================================================================
#                                      End of Variable Declarations
# ============================================================================================

