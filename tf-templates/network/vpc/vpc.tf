# --------------------------------------------------------------------------------------------
# VPC
# --------------------------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = (merge(local.common_tags, var.vpc_tags,
  map("Name", format("%s", var.vpc_name))))
}

# --------------------------------------------------------------------------------------------
# DHCP Options
# --------------------------------------------------------------------------------------------
resource "aws_vpc_dhcp_options" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type

  tags = (merge(local.common_tags, var.dhcp_options_tags,
  map("Name", format("%s", var.vpc_name))))
}

# --------------------------------------------------------------------------------------------
# DHCP Options Set Association
# --------------------------------------------------------------------------------------------
resource "aws_vpc_dhcp_options_association" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this.id
}
