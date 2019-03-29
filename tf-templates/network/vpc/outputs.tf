# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${aws_vpc.this.id}"
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = "${aws_vpc.this.cidr_block}"
}

# --------------------------------------------------------------------------------------------

# Public Route Table
output "public_route_table_id" {
  description = "The ID of the Public Route Table"
  value       = ["${aws_default_route_table.public.id}"]
}

# Private Route Tables
output "private_route_table_ids" {
  description = "The IDs of the Private Route Tables"
  value       = ["${aws_route_table.private.*.id}"]
}

# --------------------------------------------------------------------------------------------

# Route53 Private
output "private_zone_id" {
  description = "The ID of the private zone"
  value       = "${module.r53_private.zone_id}"
}

output "private_name_servers" {
  description = "The Name Servers of the private zone"
  value       = "${module.r53_private.name_servers}"
}

# --------------------------------------------------------------------------------------------

# Subnet Groups
output "db_subnet_group_name" {
  description = "The name of the db subnet group"
  value       = "${module.db-subnet-group.name}"
}

# --------------------------------------------------------------------------------------------

# Route53 Delegation Set
output "delegate_set_id" {
  description = "The ID of the delegate set"
  value       = "${module.r53_delegate.id}"
}

output "delegate_set_name_servers" {
  description = "The Name Servers of the delegate set"
  value       = "${module.r53_delegate.name_servers}"
}

# Route53 Public
output "public_zone_id" {
  description = "The ID of the public zone"
  value       = "${module.r53_public.zone_id}"
}

output "public_name_servers" {
  description = "The Name Servers of the public zone"
  value       = "${module.r53_public.name_servers}"
}
