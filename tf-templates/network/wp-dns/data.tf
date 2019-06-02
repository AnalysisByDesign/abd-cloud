# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_route53_zone" "wordpress" {
  name = "${var.wp_apex_domain}."
}

data "aws_lb" "wordpress" {
  name = "${format("%s-%s", local.vpc_name, var.wp_lb_name)}"
}
