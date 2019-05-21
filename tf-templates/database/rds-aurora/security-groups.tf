# --------------------------------------------------------------------------------------------
# Security Groups
# --------------------------------------------------------------------------------------------

module "sg-aurora" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group"

  # Required variables
  name        = "${format("%s-%s", local.vpc_name, var.name)}"
  description = "Aurora database"
  common_tags = "${local.common_tags}"
  vpc_id      = "${data.aws_vpc.vpc.id}"
}

module "sg-aurora-ingress-mysql" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-cidr"

  required = "${length(var.management_ingress_locations) > 0 ? 1 : 0}"

  # Required variables
  security_group_id = "${module.sg-aurora.id}"
  description       = "MySQL from Management locations"
  type              = "ingress"
  protocol          = "tcp"
  single_port       = "3306"
  cidr_blocks       = ["${var.management_ingress_locations}"]
}
