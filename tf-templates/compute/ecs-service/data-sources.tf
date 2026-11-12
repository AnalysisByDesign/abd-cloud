# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_ecs_cluster" "this" {
  cluster_name = var.cluster_name
}

data "aws_iam_policy" "ecr_pull" {
  name = var.ecr_pull_policy_name
}

# Existing ALB and its HTTPS listener, found by name as the hosted-sites targets do
data "aws_lb" "this" {
  count = local.load_balanced ? 1 : 0
  name  = format("%s-%s", local.vpc_name, var.load_balancer_name)
}

data "aws_lb_listener" "https" {
  count             = local.load_balanced ? 1 : 0
  load_balancer_arn = data.aws_lb.this[0].arn
  port              = 443
}

data "aws_route53_zone" "public" {
  count        = local.load_balanced && var.dns_zone_name != "" ? 1 : 0
  name         = "${var.dns_zone_name}."
  private_zone = false
}

data "aws_efs_file_system" "this" {
  count = length(var.efs_access_points) > 0 ? 1 : 0
  tags  = { Name = var.efs_file_system_name }
}

data "aws_subnet" "app" {
  count      = local.awsvpc ? length(var.private_app_subnets) : 0
  cidr_block = element(var.private_app_subnets, count.index)
}

data "aws_service_discovery_dns_namespace" "this" {
  count = local.service_discovery ? 1 : 0
  name  = var.service_discovery_namespace
  type  = "DNS_PRIVATE"
}

data "aws_sns_topic" "alerts" {
  count = local.alarms ? 1 : 0
  name  = var.alerts_topic_name
}

# -----------------------------------------------------------------------------

locals {
  full_name = format("%s-%s", local.vpc_name, var.name)
  awsvpc    = var.network_mode == "awsvpc"

  load_balanced     = length(var.hostnames) > 0
  service_discovery = local.awsvpc && var.service_discovery_namespace != ""
  alarms            = var.enable_alarms && local.load_balanced

  lb_container = var.load_balancer_container != "" ? var.load_balancer_container : var.containers[0].name
  lb_port      = one([for c in var.containers : c.port if c.name == local.lb_container])

  account_id = data.aws_caller_identity.current.account_id

  # SSM parameters any container reads as a secret
  secret_parameter_names = distinct(flatten([for c in var.containers : values(c.secrets)]))
  secret_parameter_arns = [
    for p in local.secret_parameter_names :
    format("arn:aws:ssm:%s:%s:parameter/%s", var.target_region, local.account_id, trimprefix(p, "/"))
  ]
}
