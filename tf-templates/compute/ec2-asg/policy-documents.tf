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

locals {
  ec2_asg_policy_document = var.ec2_policy_template != "" ? templatefile(
    "${var.ec2_policy_template_folder}/${var.ec2_policy_template}",
    { s3_name = var.s3_name, ssm_key_prefix = local.vpc_name, kms_key_arn = var.s3_kms_key_arn }
  ) : ""
}
