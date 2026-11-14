# =============================================================================
#                                      Required
# =============================================================================

variable "acct_apex" {
  description = "Account where Apex domain can be found"
  type        = string
}

# =============================================================================
# Wordpress Specific DNS configuration
# =============================================================================

variable "enable_wordpress" {
  description = "Enable Wordpress load balancer and DNS records"
  type        = bool
  default     = true
}

variable "enable_www_redirect" {
  description = "Enable WWW to Apex redirect DNS record"
  type        = bool
  default     = true
}

# Usually used to prepare a subdomain from abd-wp.uk
variable "wp_sub_domain" {
  description = "The public target subdomain domain prefix"
  type        = string
  default     = ""
}

variable "wp_apex_domain" {
  description = "The public target apex domain"
  type        = string
  default     = ""
}

# =============================================================================
#                                      DNS Zone
# =============================================================================

variable "delegate_set_name" {
  description = "A reference name for the delegate set"
  type        = string
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
  type        = map(string)

  default = {
    "Component" = "account"
  }
}

# =============================================================================
#                                      Website
# =============================================================================

variable "trg_lb_name" {
  description = "The load balancer name for the main WP installation"
  type        = string
  default     = ""
}

variable "ssl_cert_enabled" {
  description = "Does this site require an SSL cert. (Always false until NameServer change)"
  default     = true
}

variable "subject_alternative_names" {
  description = "Subject alternative names for the SSL cert if required"
  type        = list(string)
  default     = []
}

variable "wildcard_dns_enabled" {
  description = "Create a wildcard (*) alias record for this domain, pointing at the WP load balancer"
  type        = bool
  default     = false
}

variable "redirect_to" {
  description = "Host name to send this domain to with a 301 from the load balancer (e.g. daverix.ai), keeping the path; empty for none. Needs trg_lb_name and redirect_priority"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^([a-z0-9-]+\\.)+[a-z]+$", var.redirect_to)) || var.redirect_to == ""
    error_message = "redirect_to is a bare host name, without a scheme or path."
  }
}

variable "redirect_priority" {
  description = "Listener rule priority for redirect_to, unique on the listener (WordPress band 100s, WP-04 ruling 12)"
  type        = number
  default     = null
}

# =============================================================================
#                                      Email
# =============================================================================

variable "mx_records" {
  description = "Records to use as MX records for this zone"
  type        = list(string)
  default     = []
}

# =============================================================================
#                                    Extra Records
# =============================================================================

variable "dns_extra" {
  description = "Extra DNS records that might be required"
  type        = list(map(string))
  default     = []
}

# =============================================================================
#                                 DNS Challenge User
# =============================================================================

variable "dns_challenge_user_name" {
  description = "Name of an IAM user permitted to complete the ACME DNS-01 challenge in this zone only. Leave empty to create no user"
  type        = string
  default     = ""
}
