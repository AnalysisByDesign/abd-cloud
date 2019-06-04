# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_route53_zone" "wordpress" {
  name = "${var.wp_apex_domain}."
}

data "aws_lb" "wordpress" {
  name = "${format("%s-%s", local.vpc_name, var.wp_lb_name)}"
}

data "aws_lb_listener" "wordpress443" {
  load_balancer_arn = "${data.aws_lb.wordpress.arn}"
  port              = 443
}
