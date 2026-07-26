# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_route53_zone" "wordpress" {
  count = var.enable_wordpress ? 1 : 0
  name  = "${var.wp_apex_domain}."
}

data "aws_lb" "target" {
  name = format("%s-%s", local.vpc_name, var.trg_lb_name)
}

data "aws_lb_listener" "target443" {
  load_balancer_arn = data.aws_lb.target.arn
  port              = 443
}
