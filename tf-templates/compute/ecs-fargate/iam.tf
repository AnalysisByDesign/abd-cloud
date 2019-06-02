# --------------------------------------------------------------------------------------------
# IAM Resources
# --------------------------------------------------------------------------------------------

# Create role
module "ecs_role" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/iam-role"

  roles = [{
    name               = "${format("%s-ecs-role", local.vpc_name)}"
    description        = "${format("%s-ecs-role", local.vpc_name)}"
    assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role_policy.json}"
    policy_arn         = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  }]
}

# Create policy
#module "ecs_policy" "ecs" {
#  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//security/iam-policy"
#
#  name        = "${var.name}EcsPolicy"
#  description = "Policy for Elastic Container Service"
#  policy      = "${data.aws_iam_policy_document.ecs-policy.json}"
#}


# Attach policy
#resource "aws_iam_role_policy_attachment" "ecs" {
#  count      = "${var.ecs_policy_template == "" ? 0 : 1 }"
#  role       = "${module.ecs_role.names}"
#  policy_arn = "${module.ecs_policy.arn}"
#}

