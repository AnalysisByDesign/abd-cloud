# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

# LB Endpoint
output "fqdn_lb_actual" {
  description = "The LB endpoint for the PHP ASG"
  value       = module.load_balancer.alb_dns_name
}

# Route53 record
output "fqdn_lb" {
  description = "DNS entry for direct access to the Load Balancer"
  value       = module.dns_load_balancer.fqdn
}
