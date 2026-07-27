# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_route53_zone" "wordpress" {
  count = var.enable_wordpress ? 1 : 0
  name  = "${var.wp_apex_domain}."
}

data "aws_lb" "target" {
  count = var.trg_lb_name == "" ? 0 : 1
  name  = format("%s-%s", local.vpc_name, var.trg_lb_name)
}

data "aws_lb_listener" "target443" {
  count             = var.trg_lb_name == "" ? 0 : 1
  load_balancer_arn = data.aws_lb.target[0].arn
  port              = 443
}
