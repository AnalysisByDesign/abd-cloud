# --------------------------------------------------------------------------------------------
# Security Groups
# --------------------------------------------------------------------------------------------

resource "aws_default_security_group" "egress" {
  vpc_id = "${aws_vpc.this.id}"

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(local.common_tags,
              map("Name", format("%s-public", var.vpc_name)))}"
}

# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
# Management ingress SSH security group
# --------------------------------------------------------------------------------------------
module "management-ssh-sg" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group"

  # Required variables
  name        = "${format("%s-management-ssh", var.vpc_name)}"
  description = "Management ingress for occasional use"
  common_tags = "${local.common_tags}"
  vpc_id      = "${aws_vpc.this.id}"
}

# --------------------------------------------------------------------------------------------
module "management-ssh-sgr-in" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-cidr"

  required = "${length(var.management_ingress_locations) > 0 ? 1 : 0}"

  # Required variables
  security_group_id = "${module.management-ssh-sg.id}"
  description       = "SSH from Management locations"
  type              = "ingress"
  protocol          = "tcp"
  single_port       = "22"
  cidr_blocks       = ["${var.management_ingress_locations}"]
}

# --------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------------------------

