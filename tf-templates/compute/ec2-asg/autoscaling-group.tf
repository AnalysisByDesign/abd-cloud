# --------------------------------------------------------------------------------------------
# AutoScaling Group
# --------------------------------------------------------------------------------------------
module "autoscaling-group" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//compute/asg"

  # Required variables
  name       = "${format("%s-%s", local.vpc_name, var.name)}"
  subnet_ids = ["${data.aws_subnet.asg.*.id}"]

  # Optional variables
  launch_template_id = "${module.launch_template.id}"

  min_size                  = "${var.asg_min_size}"
  desired_capacity          = "${var.asg_desired_capacity}"
  max_size                  = "${var.asg_max_size}"
  default_cooldown          = "${var.asg_default_cooldown}"
  health_check_grace_period = "${var.asg_health_check_grace_period}"
  capacity_timeout          = "${var.asg_capacity_timeout}"
  target_group_arns         = ["${module.load_balancer.target_group_arn}"]
  health_check_type         = "ELB"
  force_delete              = "${var.asg_force_delete}"
  termination_policies      = ["${var.asg_termination_policies}"]
  delete_timeout            = "${var.asg_delete_timeout}"

  tag_map = ["${list(
      map("key", "Name",        "value", "${format("%s-%s", local.vpc_name, var.name)}", "propagate_at_launch", true),
      map("key", "Account",     "value", "${var.account_name}",           "propagate_at_launch", true),
      map("key", "Owner",       "value", "${var.common_tag_owner}",       "propagate_at_launch", true),
      map("key", "Project",     "value", "${var.common_tag_project}",     "propagate_at_launch", true),
      map("key", "SubSystem",   "value", "${var.common_tag_subsystem}",   "propagate_at_launch", true),
      map("key", "Component",   "value", "${var.common_tag_component}",   "propagate_at_launch", true),
      map("key", "Environment", "value", "${var.common_tag_environment}", "propagate_at_launch", true),
      map("key", "Provisioner", "value", "terraform",                     "propagate_at_launch", true)
    )}"]
}

module "autoscaling_group_admin" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//compute/asg"

  # Required variables
  name       = "${format("%s-%s-admin", local.vpc_name, var.name)}"
  subnet_ids = ["${data.aws_subnet.asg.*.id}"]

  # Optional variables
  launch_template_id = "${module.launch_template_admin.id}"

  min_size                  = "${var.asg_admin_min_size}"
  desired_capacity          = "${var.asg_admin_desired_capacity}"
  max_size                  = "${var.asg_admin_max_size}"
  default_cooldown          = "${var.asg_default_cooldown}"
  health_check_grace_period = "${var.asg_health_check_grace_period}"
  capacity_timeout          = "${var.asg_capacity_timeout}"
  target_group_arns         = ["${module.load_balancer_admin.target_group_arn}"]
  health_check_type         = "ELB"
  force_delete              = "${var.asg_force_delete}"
  termination_policies      = ["${var.asg_termination_policies}"]
  delete_timeout            = "${var.asg_delete_timeout}"

  tag_map = ["${list(
      map("key", "Name",        "value", "${format("%s-%s-admin", local.vpc_name, var.name)}", "propagate_at_launch", true),
      map("key", "Account",     "value", "${var.account_name}",           "propagate_at_launch", true),
      map("key", "Owner",       "value", "${var.common_tag_owner}",       "propagate_at_launch", true),
      map("key", "Project",     "value", "${var.common_tag_project}",     "propagate_at_launch", true),
      map("key", "SubSystem",   "value", "${var.common_tag_subsystem}",   "propagate_at_launch", true),
      map("key", "Component",   "value", "${var.common_tag_component}",   "propagate_at_launch", true),
      map("key", "Environment", "value", "${var.common_tag_environment}", "propagate_at_launch", true),
      map("key", "Provisioner", "value", "terraform",                     "propagate_at_launch", true)
    )}"]
}
