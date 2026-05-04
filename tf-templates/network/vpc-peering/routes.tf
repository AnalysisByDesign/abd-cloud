# --------------------------------------------------------------------------------------------
# Connection routes for traffic through the peering link
# --------------------------------------------------------------------------------------------

# --- Configure the requester routes out to the accepter

resource "aws_route" "requester_public" {
  count          = length(local.requester_public_rtb_ids)
  route_table_id = element(local.requester_public_rtb_ids, count.index)

  destination_cidr_block = (var.public_accepter_cidr_override != ""
    ? var.public_accepter_cidr_override
  : local.accepter_vpc_cidr)

  vpc_peering_connection_id = aws_vpc_peering_connection.requester.id

  timeouts {
    create = "5m"
    delete = "5m"
  }
}

resource "aws_route" "requester_private" {
  count          = length(local.requester_private_rtb_ids)
  route_table_id = element(local.requester_private_rtb_ids, count.index)

  destination_cidr_block = (var.private_accepter_cidr_override != ""
    ? var.private_accepter_cidr_override
  : local.accepter_vpc_cidr)

  vpc_peering_connection_id = aws_vpc_peering_connection.requester.id

  timeouts {
    create = "5m"
    delete = "5m"
  }
}

# --- Configure the accepter routes back to the requester

resource "aws_route" "accepter_public" {
  provider       = "aws.accepter"
  count          = length(local.accepter_public_rtb_ids)
  route_table_id = element(local.accepter_public_rtb_ids, count.index)

  destination_cidr_block = (var.public_requester_cidr_override != ""
    ? var.public_requester_cidr_override
  : local.vpc_cidr)

  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.id

  timeouts {
    create = "5m"
    delete = "5m"
  }
}

resource "aws_route" "accepter_private" {
  provider       = "aws.accepter"
  count          = length(local.accepter_private_rtb_ids)
  route_table_id = element(local.accepter_private_rtb_ids, count.index)

  destination_cidr_block = (var.private_requester_cidr_override != ""
    ? var.private_requester_cidr_override
  : local.vpc_cidr)

  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.id

  timeouts {
    create = "5m"
    delete = "5m"
  }
}
