# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

# VPC Peering Connection Options
output "requester_connection_options_id" {
  description = "The ID of the VPC Peering Connection Options"
  value       = "${aws_vpc_peering_connection_options.requester.id}"
}

output "accepter_connection_options_id" {
  description = "The ID of the VPC Peering Connection Options"
  value       = "${aws_vpc_peering_connection_options.accepter.id}"
}
