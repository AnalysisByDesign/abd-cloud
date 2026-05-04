# -----------------------------------------------------------------------------
# Policy Documents
# -----------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
# Attached to the EC2 instance IAM role
data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = []
    }
  }
}

# -----------------------------------------------------------------------------

data "template_file" "ec2_asg_policy" {
  count    = var.ec2_policy_template != "" ? 1 : 0
  template = file("${var.ec2_policy_template_folder}/${var.ec2_policy_template}")

  vars {
    s3_name        = var.s3_name
    ssm_key_prefix = local.vpc_name
  }
}
