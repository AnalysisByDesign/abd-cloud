# --------------------------------------------------------------------------------------------
# Elastic Load Balancer
# --------------------------------------------------------------------------------------------

module "load_balancer" {
  source = "../../../../abd-cloud-modules/compute/alb"

  # Required variables
  name       = format("%s-%s", local.vpc_name, var.name)
  vpc_id     = local.vpc_id
  subnet_ids = ["${data.aws_subnet.lb.*.id}"]

  security_group_ids = ["${module.alb-sg.id}"]
  acm_arn            = join("", module.ssl_cert.cert_validation_arn)

  # Health check
  path         = var.alb_health_check_path
  success_code = var.alb_health_check_status

  common_tags = local.common_tags
}
