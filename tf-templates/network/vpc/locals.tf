# --------------------------------------------------------------------------------------------
# Local Variable Definitions
# --------------------------------------------------------------------------------------------

locals {
  # Workaround for interpolation not being able to "short-circuit" the evaluation of the conditional branch that doesn't end up being used  # Source: https://github.com/hashicorp/terraform/issues/11566#issuecomment-289417805  #  # The logical expression would be   #     nat_gateway_ips = var.reuse_nat_ips ? var.external_nat_ip_ids : aws_eip.nat.*.id  # but when count of aws_eip.nat.*.id is zero, this would throw a resource not found error on aws_eip.nat.*.id.

  nat_gateway_ips = (split(",", (var.reuse_nat_ips
    ? join(",", var.external_nat_ip_ids)
  : join(",", aws_eip.nat.*.id))))
}
