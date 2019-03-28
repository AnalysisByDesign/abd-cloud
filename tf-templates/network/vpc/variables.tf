# ============================================================================================
#                                      Connectivity
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "acct_apex" {
  description = "Account where Apex domain can be found"
  type        = "string"
}

# Optional -----------------------------------------------------------------------------------

variable "azs" {
  description = "A list of AZs to be used for this deployment"
  type        = "list"
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

# ============================================================================================
#                                      VPC 
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "vpc_name" {
  description = "The name of the VPC"
  type        = "string"
}

variable "vpc_cidr" {
  description = "The VPC CIDR range for the new VPC"
  type        = "string"
}

# Optional -----------------------------------------------------------------------------------

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  type        = "map"

  default = {
    "Component" = "vpc"
  }
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = "string"
  default     = "default"
}

variable "enable_dns_hostnames" {
  description = "Set to true to enable public DNS hostnames in the VPC"
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable internal DNS support in the VPC"
  default     = true
}

# ============================================================================================
#                                      DHCP Option
# ============================================================================================

# Required -----------------------------------------------------------------------------------

# None

# Optional -----------------------------------------------------------------------------------

variable "dhcp_options_tags" {
  description = "Additional tags for the DHCP option set"
  type        = "map"

  default = {
    "Component" = "vpc"
  }
}

variable "enable_dhcp_options" {
  description = "Should be true if you want to specify a DHCP options set with a custom configuration"
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Specifies DNS name for DHCP options set"
  type        = "string"
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "Specify a list of DNS server addresses for DHCP options set, default to AWS provided"
  type        = "list"
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "Specify a list of NTP servers for DHCP options set"
  type        = "list"
  default     = []
}

variable "dhcp_options_netbios_name_servers" {
  description = "Specify a list of netbios servers for DHCP options set"
  type        = "list"
  default     = []
}

variable "dhcp_options_netbios_node_type" {
  description = "Specify netbios node_type for DHCP options set"
  type        = "string"
  default     = ""
}

# ============================================================================================
#                                      Subnets and Availability Zones
# ============================================================================================

# Required -----------------------------------------------------------------------------------

# None

# Optional -----------------------------------------------------------------------------------

variable "public_subnets" {
  description = "A list of public subnets to be used for this deployment"
  type        = "list"
  default     = []
}

variable "map_public_ip" {
  description = "Map a public IP to instances in a public subnet"
  default     = false
}

variable "private_web_subnets" {
  description = "A list of private subnets to be used for web resource within this deployment"
  type        = "list"
  default     = []
}

variable "private_app_subnets" {
  description = "A list of private subnets to be used for app resource within this deployment"
  type        = "list"
  default     = []
}

variable "private_cache_subnets" {
  description = "A list of private subnets to be used for cache storage within this deployment"
  type        = "list"
  default     = []
}

variable "private_db_subnets" {
  description = "A list of private subnets to be used for db storage within this deployment"
  type        = "list"
  default     = []
}

variable "subnet_tags" {
  description = "Additional tags for the subnets"
  type        = "map"

  default = {
    "Component" = "subnet"
  }
}

# ============================================================================================
#                                      DB Subnet Group
# ============================================================================================

# Required -----------------------------------------------------------------------------------
# None

# Optional -----------------------------------------------------------------------------------
variable "db_subnet_group_name" {
  description = "Name of DB subnet group table"
  type        = "string"
  default     = "rds-aurora"
}

variable "db_subnet_tags" {
  description = "A map of subnet tags to add to subnet group"
  type        = "map"

  default = {
    "Component" = "rds aurora"
  }
}

# ============================================================================================
#                                      Elasticache Subnet Group
# ============================================================================================

# Required -----------------------------------------------------------------------------------
# None

# Optional -----------------------------------------------------------------------------------
variable "elasticache_subnet_group_name" {
  description = "Name of Elasticache subnet group table"
  type        = "string"
  default     = "elasticache"
}

variable "elasticache_subnet_tags" {
  description = "A map of subnet tags to add to subnet group"
  type        = "map"

  default = {
    "Component" = "elasticache cluster"
  }
}

# ============================================================================================
#                                      DB Param Groups
# ============================================================================================

# Required -----------------------------------------------------------------------------------
# None

# Optional -----------------------------------------------------------------------------------
variable "db_param_group_name" {
  description = "Name of DB param group table"
  type        = "string"
  default     = "rds-aurora"
}

variable "db_param_group_tags" {
  description = "A map of tags to add to param group"
  type        = "map"

  default = {
    "Component" = "rds aurora"
  }
}

# ============================================================================================
#                                      Elasticache Param Groups
# ============================================================================================

# Required -----------------------------------------------------------------------------------
# None

# Optional -----------------------------------------------------------------------------------
variable "cache_cluster_param_group_name" {
  description = "Name of Elasticache param group table"
  type        = "string"
  default     = "redis-cluster"
}

variable "cache_cluster_param_group_tags" {
  description = "A map of tags to add to param group"
  type        = "map"

  default = {
    "Component" = "Elasticache Redis"
  }
}

# ============================================================================================
#                                      Route53
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
  description = "Do we need this sub-domain delegated from parknowportal.cloud apex domain"
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
    "Component" = "vpc"
  }
}

# ============================================================================================
#                                      Route Tables
# ============================================================================================

# Required -----------------------------------------------------------------------------------

# None

# Optional -----------------------------------------------------------------------------------

variable "public_propagating_vgws" {
  description = "A list of VGWs the public route table should propagate"
  type        = "list"
  default     = []
}

variable "public_route_table_tags" {
  description = "Additional tags for the public route tables"
  type        = "map"

  default = {
    "Component" = "route table"
  }
}

variable "private_propagating_vgws" {
  description = "A list of VGWs the private route table should propagate"
  type        = "list"
  default     = []
}

variable "private_route_table_tags" {
  description = "Additional tags for the private route tables"
  type        = "map"

  default = {
    "Component" = "route table"
  }
}

# ============================================================================================
#                                     Gateways
# ============================================================================================

# Required -----------------------------------------------------------------------------------

# None

# Optional -----------------------------------------------------------------------------------

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  default     = true
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  default     = true
}

variable "reuse_nat_ips" {
  description = "Should be true if you want to pass external NAT IPs in via the 'external_nat_ip_ids' variable"
  default     = false
}

variable "external_nat_ip_ids" {
  description = "List of EIP IDs to be assigned to the NAT Gateways (used in combination with reuse_nat_ips)"
  type        = "list"
  default     = []
}

# ============================================================================================
#                                      Direct Connect
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "connect_to_mpls" {
  description = "Connect the private route tables to the MPLS cloud via direct connect?"
  default     = false
}

# Optional -----------------------------------------------------------------------------------

variable "dx_connect_gateway_name" {
  description = "The name of the Direct Connect Gateway to attach to"
  type        = "string"
  default     = ""
}

variable "amazon_side_asn" {
  description = "AWS ASN"
  default     = "64512"
}

# ============================================================================================
#                                   VPC S3 Endpoints
# ============================================================================================

variable "vpc_endpoint_s3_enable" {
  description = "Connect an S3 VPC Endpoint to the private route tables?"
  default     = false
}

variable "vpc_endpoint_s3_web_enable" {
  description = "Connect an S3 VPC Endpoint to the Web subnets?"
  default     = false
}

variable "vpc_endpoint_s3_app_enable" {
  description = "Connect an S3 VPC Endpoint to the App subnets?"
  default     = false
}

# ============================================================================================
#                                      End of Variable Declarations
# ============================================================================================

