# --------------------------------------------------------------------------------------------
# Security Groups
# --------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
# ALB Security Group
# --------------------------------------------------------------------------------------------

module "alb-sg" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group"

  name        = format("%s-%s-alb", local.vpc_name, var.name)
  description = format("%s-%s-alb", local.vpc_name, var.name)
  common_tags = local.common_tags
  vpc_id      = data.aws_vpc.vpc.id
}

module "alb-sgr-http-in" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-cidr"

  security_group_id = module.alb-sg.id
  description       = "HTTP inbound"
  type              = "ingress"
  protocol          = "tcp"
  single_port       = "80"
  cidr_blocks       = ["${var.alb_ingress_cidr}"]
}

module "alb-sgr-https-in" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-cidr"

  security_group_id = module.alb-sg.id
  description       = "HTTPS inbound"
  type              = "ingress"
  protocol          = "tcp"
  single_port       = "443"
  cidr_blocks       = ["${var.alb_ingress_cidr}"]
}

# --------------------------------------------------------------------------------------------
# EC2 Security Group
# --------------------------------------------------------------------------------------------

module "ec2-sg" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group"

  name        = format("%s-%s-ec2", local.vpc_name, var.name)
  description = format("%s-%s-ec2", local.vpc_name, var.name)
  common_tags = local.common_tags
  vpc_id      = data.aws_vpc.vpc.id
}

module "alb-ec2-sgr" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = module.alb-sg.id
  description              = "HTTP ALB to EC2"
  type                     = "egress"
  protocol                 = "tcp"
  single_port              = "80"
  source_security_group_id = module.ec2-sg.id
}

module "ec2-alb-sgr" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = module.ec2-sg.id
  description              = "HTTP ALB to EC2"
  type                     = "ingress"
  protocol                 = "tcp"
  single_port              = "80"
  source_security_group_id = module.alb-sg.id
}

module "ec2-all-traffic-out" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-cidr"

  security_group_id = module.ec2-sg.id
  description       = "Outbound"
  type              = "egress"
  protocol          = "all"
  from_port         = "0"
  to_port           = "65535"
  cidr_blocks       = ["0.0.0.0/0"]
}

module "ec2-rds-sgr" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = module.ec2-sg.id
  description              = "MySQL EC2 to Aurora"
  type                     = "egress"
  protocol                 = "tcp"
  single_port              = "3306"
  source_security_group_id = data.aws_security_group.rds.id
}

module "rds-ec2-sgr" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = data.aws_security_group.rds.id
  description              = "MySQL EC2 to Aurora"
  type                     = "ingress"
  protocol                 = "tcp"
  single_port              = "3306"
  source_security_group_id = module.ec2-sg.id
}

module "ec2-efs-sgr" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = module.ec2-sg.id
  description              = "EC2 to EFS"
  type                     = "egress"
  protocol                 = "tcp"
  single_port              = "2049"
  source_security_group_id = data.aws_security_group.efs.id
}

module "efs-ec2-sgr" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = data.aws_security_group.efs.id
  description              = "EC2 to EFS"
  type                     = "ingress"
  protocol                 = "tcp"
  single_port              = "2049"
  source_security_group_id = module.ec2-sg.id
}
