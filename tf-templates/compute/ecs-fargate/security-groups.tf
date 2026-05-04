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
# ECS Security Group
# --------------------------------------------------------------------------------------------

module "ecs-sg" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group"

  name        = format("%s-%s-ecs", local.vpc_name, var.name)
  description = format("%s-%s-ecs", local.vpc_name, var.name)
  common_tags = local.common_tags
  vpc_id      = data.aws_vpc.vpc.id
}

module "alb-ecs-sgr" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = module.alb-sg.id
  description              = "HTTP ALB to ECS"
  type                     = "egress"
  protocol                 = "tcp"
  single_port              = "80"
  source_security_group_id = module.ecs-sg.id
}

module "ecs-alb-sgr" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = module.ecs-sg.id
  description              = "HTTP ALB to ECS"
  type                     = "ingress"
  protocol                 = "tcp"
  single_port              = "80"
  source_security_group_id = module.alb-sg.id
}

module "ecs-rds-sgr" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = module.ecs-sg.id
  description              = "MySQL ECS to Aurora"
  type                     = "egress"
  protocol                 = "tcp"
  single_port              = "3306"
  source_security_group_id = data.aws_security_group.rds.id
}

module "rds-ecs-sgr" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-link"

  security_group_id        = data.aws_security_group.rds.id
  description              = "MySQL ECS to Aurora"
  type                     = "ingress"
  protocol                 = "tcp"
  single_port              = "3306"
  source_security_group_id = module.ecs-sg.id
}

module "ecs-http-sgr" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-cidr"

  security_group_id = module.ecs-sg.id
  description       = "HTTP outbound"
  type              = "egress"
  protocol          = "tcp"
  single_port       = "80"
  cidr_blocks       = ["0.0.0.0/0"]
}

module "ecs-https-sgr" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/security-group-rule-cidr"

  security_group_id = module.ecs-sg.id
  description       = "HTTPS outbound"
  type              = "egress"
  protocol          = "tcp"
  single_port       = "443"
  cidr_blocks       = ["0.0.0.0/0"]
}
