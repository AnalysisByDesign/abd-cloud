# --------------------------------------------------------------------------------------------
# INTERNET GATEWAY
# --------------------------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  count  = "${length(var.public_subnets) > 0 ? 1 : 0}"
  vpc_id = "${aws_vpc.this.id}"

  tags = "${merge(local.common_tags, 
                    map("Name", format("%s", var.vpc_name)))}"
}

# --------------------------------------------------------------------------------------------
# NAT GATEWAY
# --------------------------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count = "${(var.enable_nat_gateway && !var.reuse_nat_ips) 
                ? (var.single_nat_gateway 
                      ? 1 
                      : length(var.azs)) 
                : 0}"

  vpc = true

  tags = "${merge(local.common_tags, 
                    map("Name", format("%s-nat-%s", var.vpc_name, element(var.azs, (var.single_nat_gateway 
                                                                                          ? 0 
                                                                                          : count.index)
                                                                        )
                                    )
                        )
                  )}"
}

# --------------------------------------------------------------------------------------------

resource "aws_nat_gateway" "this" {
  count = "${var.enable_nat_gateway 
              ? (var.single_nat_gateway 
                    ? 1 
                    : length(var.azs)) 
              : 0}"

  allocation_id = "${element(local.nat_gateway_ips,  (var.single_nat_gateway ? 0 : count.index))}"
  subnet_id     = "${element(aws_subnet.public.*.id, (var.single_nat_gateway ? 0 : count.index))}"

  tags = "${merge(local.common_tags, 
                    map("Name", format("%s-%s", var.vpc_name, element(var.azs, (var.single_nat_gateway 
                                                                                    ? 0 
                                                                                    : count.index)
                                                                  )
                                    )
                        )
                  )}"
}
