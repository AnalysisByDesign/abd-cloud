# --------------------------------------------------------------------------------------------
# Common Tag Configurations
# --------------------------------------------------------------------------------------------

variable "account_name" {
  type = "string"
}

variable "common_tag_owner" {
  type = "string"
}

variable "common_tag_project" {
  type = "string"
}

variable "common_tag_subsystem" {
  type = "string"
}

variable "common_tag_component" {
  type = "string"
}

variable "common_tag_environment" {
  type = "string"
}

# ============================================================================================
#                                      Route53
# ============================================================================================

variable "public_sub_domain" {
  description = "The public search domain prefix to create a zone for"
  type        = "string"
  default     = ""
}

variable "public_sub_domains" {
  description = "A list of public search domain prefix to create zones for"
  type        = "list"
  default     = []
}

variable "public_apex_domain" {
  description = "The public search domain suffix to create a zone for"
  type        = "string"
}

# ============================================================================================
#                                   Private CIDR Locations
# ============================================================================================

variable "management_ingress_locations" {
  description = "List of CIDR ranges for private ingress to resources"
  type        = "list"
  default     = []
}

# ============================================================================================
#                                  Local Variable Prep
# ============================================================================================

locals {
  # Common tag definitions
  common_tags = {
    Account     = "${var.account_name          }"
    Owner       = "${var.common_tag_owner      }"
    Project     = "${var.common_tag_project    }"
    SubSystem   = "${var.common_tag_subsystem  }"
    Component   = "${var.common_tag_component  }"
    Environment = "${var.common_tag_environment}"

    Provisioner = "terraform"
  }

  # Route53 search domain lists for creating new Zones
  public_sub_domains = "${coalescelist(var.public_sub_domains, list(var.public_sub_domain))}"

  # Route53 search domain for adding R53 records
  private_search_domain = "${(var.public_sub_domain == "" 
                                ? format("int.%s", var.public_apex_domain)
                                : format("int.%s.%s", var.public_sub_domain, var.public_apex_domain))}"

  private_search_domains = "${formatlist("int.%s.%s", local.public_sub_domains, var.public_apex_domain)}"

  public_search_domain = "${(var.public_sub_domain == "" 
                                ? var.public_apex_domain 
                                : format("%s.%s", var.public_sub_domain, var.public_apex_domain))}"

  public_search_domains = "${formatlist("%s.%s", local.public_sub_domains, var.public_apex_domain)}"
}
