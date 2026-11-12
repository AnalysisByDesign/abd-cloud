# --------------------------------------------------------------------------------------------
# Launch Template
# --------------------------------------------------------------------------------------------
module "launch_template" {
  source = "../../../../abd-cloud-modules/compute/launch-template"

  # Required variables
  name               = format("%s-%s", local.vpc_name, var.name)
  ami_id             = local.ami_id
  security_group_ids = [module.ec2-sg.id]
  common_tags        = local.common_tags

  # Optional variables
  ec2_instance_type = var.asg_ec2_instance_type
  ssh_key_name      = format("%s-%s", local.vpc_name, var.asg_ssh_key_name)
  require_public_ip = var.asg_require_public_ip
  iam_profile_id    = aws_iam_instance_profile.ec2-asg.name

  cpu_credits                          = var.asg_cpu_credits
  metadata_http_tokens                 = var.asg_metadata_http_tokens
  metadata_http_put_response_hop_limit = var.asg_metadata_http_put_response_hop_limit

  user_data_script = local.user_data_script
}

locals {
  user_data_script = base64encode(templatefile(
    "${var.user_data_script_folder}/${var.user_data_script}",
    merge(var.extra_template_vars, local.computed_template_vars, { env = var.common_tag_environment, name = var.name })
  ))
}
