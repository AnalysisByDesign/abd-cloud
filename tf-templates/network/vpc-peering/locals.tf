# --------------------------------------------------------------------------------------------

locals {
  accepter_vpc_id   = "${data.aws_vpc.accepter_vpc.id}"
  accepter_vpc_cidr = "${data.aws_vpc.accepter_vpc.cidr_block}"
  accepter_vpc_tags = "${data.aws_vpc.accepter_vpc.tags}"

  requester_public_rtb_ids  = "${data.terraform_remote_state.requester.public_route_table_id}"
  requester_private_rtb_ids = "${data.terraform_remote_state.requester.private_route_table_ids}"

  accepter_public_rtb_ids  = "${data.terraform_remote_state.accepter.public_route_table_id}"
  accepter_private_rtb_ids = "${data.terraform_remote_state.accepter.private_route_table_ids}"
}
