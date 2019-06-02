# ============================================================================================
#                                      Required
# ============================================================================================

variable "acct_apex" {
  description = "Account where Apex domain can be found"
  type        = "string"
}

variable "wp_sub_domain" {
  description = "The public wordpress subdomain domain prefix"
  type        = "string"
}

variable "wp_apex_domain" {
  description = "The public wordpress apex domain"
  type        = "string"
}

variable "wp_lb_name" {
  description = "The load balancer name for the main WP installation"
  type        = "string"
}

# ============================================================================================
#                                      DNS Zone
# ============================================================================================

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

variable "ssl_cert_enabled" {
  description = "Does this site require an SSL cert. (Always false until NameServer change)"
  default     = true
}

# ============================================================================================
#                                      Email
# ============================================================================================

variable "mx_records" {
  description = "Records to use as MX records for this zone"
  type        = "list"
  default     = []
}
