# --------------------------------------------------------------------------------------------
# Load Balancer Connectivity
# --------------------------------------------------------------------------------------------
resource "aws_lb_listener_certificate" "example" {
  count = "${var.ssl_cert_enabled ? 1 : 0}"

  listener_arn    = "${data.aws_lb_listener.wordpress443.arn}"
  certificate_arn = "${join("", module.ssl_cert.cert_validation_arn)}"
}
