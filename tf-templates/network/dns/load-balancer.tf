# --------------------------------------------------------------------------------------------
# Load Balancer Connectivity
# --------------------------------------------------------------------------------------------
resource "aws_lb_listener_certificate" "example" {
  count = var.ssl_cert_enabled ? 1 : 0

  listener_arn    = data.aws_lb_listener.target443[0].arn
  certificate_arn = join("", module.ssl_cert.cert_validation_arn)
}

# A domain that only redirects (e.g. daverix.uk to daverix.ai, WP-05 ruling 10): a 301 from
# the ALB for the apex, its alternative names and its abd-wp.uk subdomain, keeping the path
# and query string. No target group or host is involved.
locals {
  redirect_hostnames = concat(
    [local.public_search_domain],
    var.subject_alternative_names,
    var.enable_wordpress && var.wp_sub_domain != "" ? ["${var.wp_sub_domain}.${var.wp_apex_domain}"] : [],
  )
}

resource "aws_lb_listener_rule" "redirect" {
  count = var.redirect_to != "" ? 1 : 0

  listener_arn = one(data.aws_lb_listener.target443[*].arn)
  priority     = var.redirect_priority

  action {
    type = "redirect"

    redirect {
      host        = var.redirect_to
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = local.redirect_hostnames
    }
  }

  tags = merge(local.common_tags, { Name = "redirect-${local.public_search_domain}" })

  lifecycle {
    precondition {
      condition     = var.trg_lb_name != "" && var.redirect_priority != null
      error_message = "A redirect needs trg_lb_name and redirect_priority."
    }
    precondition {
      condition     = length(local.redirect_hostnames) <= 5
      error_message = "A listener rule matches at most five host names."
    }
  }
}
