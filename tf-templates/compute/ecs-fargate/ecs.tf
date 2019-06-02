# --------------------------------------------------------------------------------------------
# ECS Fargate
# --------------------------------------------------------------------------------------------

# Create cluster
module "ecs_cluster" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//compute/ecs/cluster"
  name   = "${format("%s-%s", local.vpc_name, var.name)}"
}

# Create task definition
module "ecs_task_definitions" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//compute/ecs/task"

  family                   = "${format("%s-%s", local.vpc_name, var.name)}"
  role_arn                 = "${module.ecs_role.arns}"
  network_mode             = "${var.network_mode}"
  requires_compatibilities = "FARGATE"

  container_definitions = "${data.template_file.tasks_tpl.rendered}"
  cpu                   = "${var.task_definition_cpu}"
  memory                = "${var.task_definition_memory}"
}

# Create service
module "ecs_service" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//compute/ecs/service"

  name              = "${format("%s-%s", local.vpc_name, var.name)}"
  cluster_id        = "${module.ecs_cluster.cluster_id}"
  task_definition   = "${module.ecs_task_definitions.definition_arn}"
  desired_count     = "${var.desired_count}"
  launch_type       = "FARGATE"
  subnet_ids        = "${data.aws_subnet.app.*.id}"
  container_name    = "${format("%s-%s", local.vpc_name, var.name)}"
  container_port    = "${var.container_port}"
  target_group_arn  = "${module.load_balancer.target_group_arn}"
  security_group_id = "${module.ecs-sg.id}"
  depends_on        = "${module.load_balancer.target_group_arn}"
}
