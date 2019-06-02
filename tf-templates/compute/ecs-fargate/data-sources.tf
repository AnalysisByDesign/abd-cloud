# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_subnet" "lb" {
  count      = "${length(var.public_subnets)}"
  cidr_block = "${element(var.public_subnets, count.index)}"
}

data "aws_subnet" "app" {
  count      = "${length(var.private_app_subnets)}"
  cidr_block = "${element(var.private_app_subnets, count.index)}"
}

# -----------------------------------------------------------------------------

data "aws_security_group" "rds" {
  name = "${format("%s-%s", local.vpc_name, var.rds_security_group)}"
}

# -----------------------------------------------------------------------------

data "aws_route53_zone" "public" {
  name = "${local.public_search_domain}."
}

# -----------------------------------------------------------------------------

data "template_file" "tasks_tpl" {
  template = "${file("${var.tasks_folder}/${var.tasks_file}")}"

  vars {
    container_name        = "${format("%s-%s", local.vpc_name, var.name)}"
    docker_image          = "${var.docker_image}"
    container_port        = "${var.container_port}"
    awslogs-group         = "${var.awslogs_group}"
    awslogs-region        = "${var.target_region}"
    awslogs-stream-prefix = "${format("%s-%s", local.vpc_name, var.name)}"
  }
}
