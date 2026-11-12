# --------------------------------------------------------------------------------------------
# Logs
# --------------------------------------------------------------------------------------------

module "log_group" {
  source = "../../../../abd-cloud-modules/monitoring/cloudwatch/group"

  cloudwatch_loggroup_names = [format("/ecs/%s/%s", local.vpc_name, var.name)]
  retention_in_days         = var.log_retention_days
  common_tags               = local.common_tags
  cloudwatch_tags           = {}
}

# --------------------------------------------------------------------------------------------
# EFS access points: each volume sees only its own directory, as the image's user
# --------------------------------------------------------------------------------------------

resource "aws_efs_access_point" "this" {
  for_each = var.efs_access_points

  file_system_id = data.aws_efs_file_system.this[0].id

  posix_user {
    uid = each.value.uid
    gid = each.value.gid
  }

  root_directory {
    path = each.value.path

    creation_info {
      owner_uid   = each.value.uid
      owner_gid   = each.value.gid
      permissions = each.value.permissions
    }
  }

  tags = merge(local.common_tags, { Name = format("%s-%s", local.full_name, each.key) })
}

# --------------------------------------------------------------------------------------------
# Task definition
# --------------------------------------------------------------------------------------------

locals {
  # Container definitions, with null and empty settings left out so the registered
  # definition matches what ECS returns (avoiding a permanent diff)
  container_definitions = [
    for c in var.containers : {
      for k, v in {
        name                   = c.name
        image                  = c.image
        essential              = c.essential
        cpu                    = c.cpu
        memory                 = c.memory
        memoryReservation      = c.memory_reservation
        command                = c.command
        entryPoint             = c.entry_point
        user                   = c.user
        readonlyRootFilesystem = c.readonly_root_filesystem
        stopTimeout            = c.stop_timeout

        portMappings = c.port == null ? null : [{
          containerPort = c.port
          hostPort      = local.awsvpc ? c.port : 0
          protocol      = "tcp"
        }]

        environment = length(c.environment) == 0 ? null : [
          for name in sort(keys(c.environment)) : { name = name, value = c.environment[name] }
        ]

        secrets = length(c.secrets) == 0 ? null : [
          for name in sort(keys(c.secrets)) : {
            name      = name
            valueFrom = format("arn:aws:ssm:%s:%s:parameter/%s", var.target_region, local.account_id, trimprefix(c.secrets[name], "/"))
          }
        ]

        mountPoints = length(c.mount_points) == 0 ? null : [
          for m in c.mount_points : {
            sourceVolume  = m.source_volume
            containerPath = m.container_path
            readOnly      = m.read_only
          }
        ]

        linuxParameters = length(c.tmpfs) == 0 ? null : {
          tmpfs = [for t in c.tmpfs : { containerPath = t.container_path, size = t.size_mib }]
        }

        healthCheck = c.health_check == null ? null : {
          command     = c.health_check.command
          interval    = c.health_check.interval
          timeout     = c.health_check.timeout
          retries     = c.health_check.retries
          startPeriod = c.health_check.start_period
        }

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = module.log_group.names_of_groups[0]
            "awslogs-region"        = var.target_region
            "awslogs-stream-prefix" = c.name
          }
        }
      } : k => v if v != null
    }
  ]
}

module "task" {
  source = "../../../../abd-cloud-modules/compute/ecs/task"

  family                   = local.full_name
  container_definitions    = jsonencode(local.container_definitions)
  requires_compatibilities = "EC2"
  network_mode             = var.network_mode
  cpu                      = null
  memory                   = null
  cpu_architecture         = var.cpu_architecture
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  # Keep earlier revisions registered: CI deploys revisions of this family too
  skip_destroy = true

  volumes = [
    for name, ap in var.efs_access_points : {
      name = name
      efs = {
        file_system_id  = data.aws_efs_file_system.this[0].id
        access_point_id = aws_efs_access_point.this[name].id
      }
    }
  ]

  common_tags = local.common_tags
}
