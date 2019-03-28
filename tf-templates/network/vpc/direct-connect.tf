# --------------------------------------------------------------------------------------------
# Direct Connect and Virtual Private Gateway with Route Propagation
# --------------------------------------------------------------------------------------------

data "aws_dx_gateway" "this" {
  count = "${var.connect_to_mpls ? 1 : 0}"
  name  = "${var.dx_connect_gateway_name}"
}

resource "aws_vpn_gateway" "this" {
  count           = "${var.connect_to_mpls ? 1 : 0}"
  vpc_id          = "${aws_vpc.this.id}"
  amazon_side_asn = "${var.amazon_side_asn}"
  tags            = "${merge(local.common_tags, 
                       map("Name", format("%s-mpls", var.vpc_name)))}"
}

resource "aws_vpn_gateway_route_propagation" "this" {
  count          = "${var.connect_to_mpls ? length(var.azs) : 0}"
  vpn_gateway_id = "${aws_vpn_gateway.this.id}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_dx_gateway_association" "this" {
  count          = "${var.connect_to_mpls ? 1 : 0}"
  dx_gateway_id  = "${data.aws_dx_gateway.this.id}"
  vpn_gateway_id = "${aws_vpn_gateway.this.id}"
}
