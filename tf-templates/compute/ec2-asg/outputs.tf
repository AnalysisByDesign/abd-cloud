# --------------------------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------------------------

# LB Endpoint
output "fqdn_lb_actual" {
  description = "The LB endpoint for the PHP ASG"
  value       = var.enable_load_balancer ? module.load_balancer[0].alb_dns_name : null
}

# Route53 record
output "fqdn_lb" {
  description = "DNS entry for direct access to the Load Balancer"
  value       = var.enable_load_balancer ? module.dns_load_balancer[0].fqdn : null
}
