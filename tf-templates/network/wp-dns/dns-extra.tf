# -----------------------------------------------------------------------------
# An optional list of Route53 Regular Records
# -----------------------------------------------------------------------------

resource "aws_route53_record" "this" {
  count = "${length(var.dns_extra)}"

  zone_id = "${module.r53_public.zone_id}"
  name    = "${lookup(var.dns_extra[count.index], "name")}"
  type    = "${lookup(var.dns_extra[count.index], "type")}"

  ttl     = "${lookup(var.dns_extra[count.index], "ttl")}"
  records = ["${split("###", lookup(var.dns_extra[count.index], "value"))}"]

  lifecycle {
    create_before_destroy = true
  }
}
