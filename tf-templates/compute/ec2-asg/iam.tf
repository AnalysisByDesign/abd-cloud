# --------------------------------------------------------------------------------------------
# IAM Resources
# --------------------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "ec2-asg" {
  name = "${format("%s-%s", local.vpc_name, var.name)}"
  path = "/"
  role = "${module.ec2_asg_role.names}"
}

module "ec2_asg_role" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/iam-role"

  roles = [{
    name               = "${format("%s-%s", local.vpc_name, var.asg_iam_profile_name)}"
    description        = "${format("%s-%s", local.vpc_name, var.asg_iam_profile_name)}"
    assume_role_policy = "${data.aws_iam_policy_document.instance_assume_role_policy.json}"
    policy_arn         = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }]
}

module "ec2_asg_policy" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/iam-policy"

  count       = "${var.ec2_policy_template == "" ? 0 : 1 }"
  name        = "${format("%s-%s", local.vpc_name, var.asg_iam_profile_name)}"
  description = "Allow EC2 instance to use selected bucket"
  policy      = "${join("", data.template_file.ec2_asg_policy.*.rendered)}"
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  count      = "${var.ec2_policy_template == "" ? 0 : 1 }"
  role       = "${module.ec2_asg_role.names}"
  policy_arn = "${module.ec2_asg_policy.arn}"
}

#resource "aws_iam_role_policy_attachment" "attach_cloudwatch" {
#  role       = "${module.ec2_asg_role.names}"
#  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
#}

