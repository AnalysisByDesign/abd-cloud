# --------------------------------------------------------------------------------------------
# AutoScaling Group
# --------------------------------------------------------------------------------------------
module "autoscaling-group" {
  source = "../../../../abd-cloud-modules/compute/asg"

  # Required variables
  name       = format("%s-%s", local.vpc_name, var.name)
  subnet_ids = data.aws_subnet.asg[*].id

  # Optional variables
  launch_template_id      = module.launch_template.id
  launch_template_version = module.launch_template.latest_version

  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_desired_capacity
  max_size                  = var.asg_max_size
  default_cooldown          = var.asg_default_cooldown
  health_check_grace_period = var.asg_health_check_grace_period
  capacity_timeout          = var.asg_capacity_timeout
  target_group_arns         = [module.load_balancer.target_group_arn]
  health_check_type         = "ELB"
  force_delete              = var.asg_force_delete
  termination_policies      = var.asg_termination_policies
  delete_timeout            = var.asg_delete_timeout

  enable_instance_refresh                 = var.asg_enable_instance_refresh
  instance_refresh_min_healthy_percentage = var.asg_instance_refresh_min_healthy_percentage
  instance_refresh_max_healthy_percentage = var.asg_instance_refresh_max_healthy_percentage
  instance_refresh_instance_warmup        = var.asg_instance_refresh_instance_warmup
  instance_refresh_triggers               = var.asg_instance_refresh_triggers

  tag_map = [
    { key = "Name", value = format("%s-%s", local.vpc_name, var.name), propagate_at_launch = true },
    { key = "Account", value = var.account_name, propagate_at_launch = true },
    { key = "Owner", value = var.common_tag_owner, propagate_at_launch = true },
    { key = "Project", value = var.common_tag_project, propagate_at_launch = true },
    { key = "SubSystem", value = var.common_tag_subsystem, propagate_at_launch = true },
    { key = "Component", value = var.common_tag_component, propagate_at_launch = true },
    { key = "Environment", value = var.common_tag_environment, propagate_at_launch = true },
    { key = "Provisioner", value = "terraform", propagate_at_launch = true },
  ]
}
