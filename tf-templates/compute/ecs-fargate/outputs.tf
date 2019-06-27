# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

# LB Endpoint
output "fqdn_lb_actual" {
  description = "The LB endpoint for the PHP ASG"
  value       = "${module.load_balancer.alb_dns_name}"
}

# Route53 record
output "fqdn_lb" {
  description = "The FQDN of the R53 record fronting the LB for the PHP ASG"
  value       = "${module.dns_apex.fqdn}"
}
