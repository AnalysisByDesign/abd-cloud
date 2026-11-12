# --------------------------------------------------------------------------------------------
# IAM: one execution role (ECS starting the task) and one task role (the running
# containers) per service
# --------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

# --------------------------------------------------------------------------------------------
# Execution role: pull images (ecr-pull-abd), write to its own log group, and read exactly
# the SSM parameters its containers use as secrets

resource "aws_iam_role" "execution" {
  name               = format("%s-ecs-%s-execution", local.vpc_name, var.name)
  description        = format("ECS execution role for service %s", local.full_name)
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "execution_ecr_pull" {
  role       = aws_iam_role.execution.name
  policy_arn = data.aws_iam_policy.ecr_pull.arn
}

data "aws_iam_policy_document" "execution" {
  statement {
    sid       = "WriteOwnLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${module.log_group.groups_arn[0]}:*"]
  }

  # SecureStrings use the AWS managed aws/ssm key, whose key policy already allows
  # decryption through SSM, so no KMS permission is needed
  dynamic "statement" {
    for_each = length(local.secret_parameter_arns) > 0 ? [1] : []
    content {
      sid       = "ReadOwnSecrets"
      actions   = ["ssm:GetParameters"]
      resources = local.secret_parameter_arns
    }
  }
}

resource "aws_iam_role_policy" "execution" {
  name   = "service"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution.json
}

# --------------------------------------------------------------------------------------------
# Task role: nothing by default; EFS mounts through its access points, ECS Exec when on,
# and any managed policies the service needs

resource "aws_iam_role" "task" {
  name               = format("%s-ecs-%s-task", local.vpc_name, var.name)
  description        = format("ECS task role for service %s", local.full_name)
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "task" {
  count = length(var.efs_access_points) > 0 || var.enable_execute_command ? 1 : 0

  dynamic "statement" {
    for_each = var.efs_access_points
    content {
      sid = "EfsAccessPoint${replace(title(replace(statement.key, "-", " ")), " ", "")}"
      actions = concat(
        ["elasticfilesystem:ClientMount"],
        statement.value.read_only ? [] : ["elasticfilesystem:ClientWrite"],
      )
      resources = [data.aws_efs_file_system.this[0].arn]

      condition {
        test     = "StringEquals"
        variable = "elasticfilesystem:AccessPointArn"
        values   = [aws_efs_access_point.this[statement.key].arn]
      }
    }
  }

  dynamic "statement" {
    for_each = var.enable_execute_command ? [1] : []
    content {
      sid = "EcsExec"
      actions = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel",
      ]
      resources = ["*"]
    }
  }
}

resource "aws_iam_role_policy" "task" {
  count = length(data.aws_iam_policy_document.task)

  name   = "service"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task[0].json
}

resource "aws_iam_role_policy_attachment" "task" {
  for_each = toset(var.task_role_policy_arns)

  role       = aws_iam_role.task.name
  policy_arn = each.value
}
