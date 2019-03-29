# --------------------------------------------------------------------------------------------
# VPC Peering Connection
# --------------------------------------------------------------------------------------------

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "requester" {
  vpc_id        = "${local.vpc_id}"
  peer_vpc_id   = "${local.accepter_vpc_id}"
  peer_owner_id = "${data.aws_caller_identity.accepter.account_id}"
  peer_region   = "${var.accepter_region != "" ? var.accepter_region : var.target_region}"
  auto_accept   = false

  tags = "${merge(local.common_tags,
              map("Peer Side", "Requester"),
              map("Peer Requester", format("%s / %s", local.vpc_tags["Account"], local.vpc_tags["Name"])),
              map("Peer Accepter", format("%s / %s", local.accepter_vpc_tags["Account"], local.accepter_vpc_tags["Name"])),
              map("Name", format("%s → %s", local.vpc_tags["Name"], local.accepter_vpc_tags["Name"])))}"
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "accepter" {
  provider = "aws.accepter"

  vpc_peering_connection_id = "${aws_vpc_peering_connection.requester.id}"
  auto_accept               = true

  tags = "${merge(local.common_tags,
              map("Peer Side", "Accepter"),
              map("Peer Requester", format("%s / %s", local.vpc_tags["Account"], local.vpc_tags["Name"])),
              map("Peer Accepter", format("%s / %s", local.accepter_vpc_tags["Account"], local.accepter_vpc_tags["Name"])),
              map("Name", format("%s ← %s", local.accepter_vpc_tags["Name"], local.vpc_tags["Name"])))}"

  lifecycle {
    ignore_changes = ["tags"]
  }
}

resource "aws_vpc_peering_connection_options" "requester" {
  # As options can't be set until the connection has been accepted
  # create an explicit dependency on the accepter.
  vpc_peering_connection_id = "${aws_vpc_peering_connection_accepter.accepter.id}"
}

resource "aws_vpc_peering_connection_options" "accepter" {
  provider = "aws.accepter"

  vpc_peering_connection_id = "${aws_vpc_peering_connection_accepter.accepter.id}"
}
