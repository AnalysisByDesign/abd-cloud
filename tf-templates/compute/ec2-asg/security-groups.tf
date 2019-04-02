# --------------------------------------------------------------------------------------------
# Security Groups
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
# ALB Security Group
# --------------------------------------------------------------------------------------------

module "alb-sg" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group"

  name        = "${format("%s-%s-alb", local.vpc_name, var.name)}"
  description = "${format("%s-%s-alb", local.vpc_name, var.name)}"
  common_tags = "${local.common_tags}"
  vpc_id      = "${data.aws_vpc.vpc.id}"
}

module "alb-sgr-http-in" "http" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-cidr"

  required = "${length(var.management_ingress_locations) > 0 ? 1 : 0}"

  security_group_id = "${module.alb-sg.id}"
  description       = "HTTP inbound"
  type              = "ingress"
  protocol          = "tcp"
  single_port       = "80"
  cidr_blocks       = ["${var.management_ingress_locations}"]
}

module "alb-sgr-https-in" "https" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-cidr"

  required = "${length(var.management_ingress_locations) > 0 ? 1 : 0}"

  security_group_id = "${module.alb-sg.id}"
  description       = "HTTPS inbound"
  type              = "ingress"
  protocol          = "tcp"
  single_port       = "443"
  cidr_blocks       = ["${var.management_ingress_locations}"]
}

# --------------------------------------------------------------------------------------------
# EC2 Security Group
# --------------------------------------------------------------------------------------------

module "ec2-sg" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group"

  name        = "${format("%s-%s-ec2", local.vpc_name, var.name)}"
  description = "${format("%s-%s-ec2", local.vpc_name, var.name)}"
  common_tags = "${local.common_tags}"
  vpc_id      = "${data.aws_vpc.vpc.id}"
}

module "alb-ec2-sgr" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = "${module.alb-sg.id}"
  description              = "HTTP ALB to EC2"
  type                     = "egress"
  protocol                 = "tcp"
  single_port              = "80"
  source_security_group_id = "${module.ec2-sg.id}"
}

module "ec2-alb-sgr" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = "${module.ec2-sg.id}"
  description              = "HTTP ALB to EC2"
  type                     = "ingress"
  protocol                 = "tcp"
  single_port              = "80"
  source_security_group_id = "${module.alb-sg.id}"
}

module "ec2-http-out" "http" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-cidr"

  security_group_id = "${module.ec2-sg.id}"
  description       = "HTTP outbound"
  type              = "egress"
  protocol          = "tcp"
  single_port       = "80"
  cidr_blocks       = ["0.0.0.0/0"]
}

module "ec2-https-out" "http" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-cidr"

  security_group_id = "${module.ec2-sg.id}"
  description       = "HTTPS outbound"
  type              = "egress"
  protocol          = "tcp"
  single_port       = "443"
  cidr_blocks       = ["0.0.0.0/0"]
}

module "ec2-rds-sgr" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = "${module.ec2-sg.id}"
  description              = "MySQL EC2 to Aurora"
  type                     = "egress"
  protocol                 = "tcp"
  single_port              = "3306"
  source_security_group_id = "${data.aws_security_group.rds.id}"
}

module "rds-ec2-sgr" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = "${data.aws_security_group.rds.id}"
  description              = "MySQL EC2 to Aurora"
  type                     = "ingress"
  protocol                 = "tcp"
  single_port              = "3306"
  source_security_group_id = "${module.ec2-sg.id}"
}