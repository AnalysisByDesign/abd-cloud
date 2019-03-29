# --------------------------------------------------------------------------------------------
# Security Groups
# --------------------------------------------------------------------------------------------

module "rds-aurora" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group"

  # Required variables
  name        = "${format("%s-%s", local.vpc_name, var.name)}"
  description = "Aurora database"
  common_tags = "${local.common_tags}"
  vpc_id      = "${data.aws_vpc.vpc.id}"
}

module "rds-aurora-in-mysql" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-cidr"

  # Required variables
  security_group_id = "${module.rds-aurora.id}"
  description       = "MySQL from Management locations"
  type              = "ingress"
  protocol          = "tcp"
  single_port       = "3306"
  cidr_blocks       = ["${var.management_ingress_locations}"]
}
