# ============================================================================================
#                                      Common
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "acct_apex" {
  description = "Account where Apex domain can be found"
  type        = "string"
}

# ============================================================================================
#                                      DNS Zone
# ============================================================================================

# Required -----------------------------------------------------------------------------------

# None

# Optional -----------------------------------------------------------------------------------

variable "delegate_set_name" {
  description = "A reference name for the delegate set"
  type        = "string"
  default     = ""
}

variable "delegation_enabled" {
  description = "Do we need this sub-domain delegated from our apex domain"
  default     = false
}

variable "use_existing_zones" {
  description = "Re-use existing public and private zones"
  default     = false
}

variable "r53_tags" {
  description = "Additional tags for the Route53 Entries"
  type        = "map"

  default = {
    "Component" = "account"
  }
}

# ============================================================================================
#                                      Website
# ============================================================================================

# Required -----------------------------------------------------------------------------------

# None

variable "web_ip4" {
  description = ""
  type        = "string"
  default     = ""
}

variable "web_ip6" {
  description = ""
  type        = "string"
  default     = ""
}

# ============================================================================================
#                                      Email
# ============================================================================================


# Required -----------------------------------------------------------------------------------


# None

