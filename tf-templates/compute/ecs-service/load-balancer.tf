# --------------------------------------------------------------------------------------------
# Target group and host-header rule on the existing ALB's HTTPS listener. The ALB itself,
# its certificates and its default action belong to other targets.
# --------------------------------------------------------------------------------------------

resource "aws_lb_target_group" "this" {
  count = local.load_balanced ? 1 : 0

  name        = var.target_group_name != "" ? var.target_group_name : local.full_name
  vpc_id      = local.vpc_id
  protocol    = "HTTP"
  port        = local.lb_port
  target_type = local.awsvpc ? "ip" : "instance"

  deregistration_delay = var.deregistration_delay

  health_check {
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    port                = "traffic-port"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, { Name = var.target_group_name != "" ? var.target_group_name : local.full_name })

  lifecycle {
    precondition {
      condition     = length(var.target_group_name != "" ? var.target_group_name : local.full_name) <= 32
      error_message = "Target group names are limited to 32 characters; set target_group_name."
    }
    precondition {
      condition     = local.lb_port != null
      error_message = "The load balancer container needs a port."
    }
  }
}

resource "aws_lb_listener_rule" "this" {
  count = local.load_balanced ? 1 : 0

  listener_arn = data.aws_lb_listener.https[0].arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  condition {
    host_header {
      values = var.hostnames
    }
  }

  tags = merge(local.common_tags, { Name = local.full_name })

  lifecycle {
    precondition {
      condition     = var.listener_rule_priority != null
      error_message = "Set listener_rule_priority when hostnames are given."
    }
  }
}

# Alias records for the host names in dns_zone_name, when this target owns their DNS (e.g.
# test and preview hostnames). Host names in other zones (a site's own domain at cutover,
# WP-05 ruling 27) keep the records their hosted-sites target manages.
resource "aws_route53_record" "this" {
  for_each = local.load_balanced && var.dns_zone_name != "" ? toset([
    for h in var.hostnames : h if h == var.dns_zone_name || endswith(h, ".${var.dns_zone_name}")
  ]) : toset([])

  zone_id = data.aws_route53_zone.public[0].zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = data.aws_lb.this[0].dns_name
    zone_id                = data.aws_lb.this[0].zone_id
    evaluate_target_health = false
  }
}
