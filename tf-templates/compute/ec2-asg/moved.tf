# --------------------------------------------------------------------------------------------
# Moved blocks: count was added to these module calls so the load balancer, RDS and EFS
# access can be switched off (WP-01). They migrate state from the bare module address to
# the [0]-indexed address, and are a no-op once state is at the new address.
# --------------------------------------------------------------------------------------------

moved {
  from = module.load_balancer
  to   = module.load_balancer[0]
}

moved {
  from = module.dns_load_balancer
  to   = module.dns_load_balancer[0]
}

moved {
  from = module.alb-sg
  to   = module.alb-sg[0]
}

moved {
  from = module.alb-sgr-http-in
  to   = module.alb-sgr-http-in[0]
}

moved {
  from = module.alb-sgr-https-in
  to   = module.alb-sgr-https-in[0]
}

moved {
  from = module.alb-ec2-sgr
  to   = module.alb-ec2-sgr[0]
}

moved {
  from = module.ec2-alb-sgr
  to   = module.ec2-alb-sgr[0]
}

moved {
  from = module.ec2-rds-sgr
  to   = module.ec2-rds-sgr[0]
}

moved {
  from = module.rds-ec2-sgr
  to   = module.rds-ec2-sgr[0]
}

moved {
  from = module.ec2-efs-sgr
  to   = module.ec2-efs-sgr[0]
}

moved {
  from = module.efs-ec2-sgr
  to   = module.efs-ec2-sgr[0]
}
