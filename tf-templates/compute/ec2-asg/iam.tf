# --------------------------------------------------------------------------------------------
# IAM Resources
# --------------------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "this" {
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
  description = "Allow EC2 instance to use S3 proofs bucket"
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

# --------------------------------------------------------------------------------------------
# Create the user account required to access the S3 bucket
# This will eventually be replaced with IAM auth in the PHP app
resource "aws_iam_user" "s3_user" {
  name          = "${format("%s-%s", local.vpc_name, var.name)}"
  path          = "/"
  force_destroy = false
}

resource "aws_iam_user_policy_attachment" "attach_policy" {
  count      = "${var.ec2_policy_template == "" ? 0 : 1 }"
  user       = "${aws_iam_user.s3_user.name}"
  policy_arn = "${module.ec2_asg_policy.arn}"
}
