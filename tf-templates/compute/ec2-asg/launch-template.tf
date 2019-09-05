# --------------------------------------------------------------------------------------------
# Launch Template
# --------------------------------------------------------------------------------------------
module "launch_template" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//compute/launch-template"

  # Required variables
  name               = "${format("%s-%s", local.vpc_name, var.name)}"
  image_id           = "${data.aws_ami.this.id}"
  security_group_ids = ["${module.ec2-sg.id}"]
  common_tags        = "${local.common_tags}"

  # Optional variables
  ec2_instance_type = "${var.asg_ec2_instance_type}"
  ssh_key_name      = "${format("%s-%s", local.vpc_name, var.asg_ssh_key_name)}"
  require_public_ip = false
  iam_profile_id    = "${aws_iam_instance_profile.ec2-asg.name}"

  user_data_script = "${local.user_data_script}"
}

module "launch_template_admin" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//compute/launch-template"

  # Required variables
  name               = "${format("%s-%s-admin", local.vpc_name, var.name)}"
  image_id           = "${data.aws_ami.this.id}"
  security_group_ids = ["${module.ec2-sg.id}"]
  common_tags        = "${local.common_tags}"

  # Optional variables
  ec2_instance_type = "${var.asg_admin_ec2_instance_type}"
  ssh_key_name      = "${format("%s-%s", local.vpc_name, var.asg_ssh_key_name)}"
  require_public_ip = false
  iam_profile_id    = "${aws_iam_instance_profile.ec2-asg.name}"

  user_data_script = "${local.user_data_script}"
}

locals {
  user_data_script = "${base64encode(data.template_file.user_data_script.rendered)}"
}

data "template_file" "user_data_script" {
  template = "${file("${var.user_data_script_folder}/${var.user_data_script}")}"

  vars {
    env  = "${var.common_tag_environment}"
    name = "${var.name}"
  }
}
