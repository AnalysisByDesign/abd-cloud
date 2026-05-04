# -----------------------------------------------------------------------------
# Policy Documents
# -----------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
# Attached to the ECS IAM role
data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = []
    }
  }
}
