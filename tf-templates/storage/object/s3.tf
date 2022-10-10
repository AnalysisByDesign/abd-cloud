# --------------------------------------------------------------------------------------------
# S3 Bucket
# --------------------------------------------------------------------------------------------

data "template_file" "s3-policy" {
  template = file("${var.policy_folder}/${var.policy_file}")

  vars {
    s3_name    = var.s3_name
    account_id = var.acct_target
  }
}

# --------------------------------------------------------------------------------------------
module "abd-s3" "object" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//storage/aws-s3"

  # Required variables
  name        = var.s3_name
  common_tags = local.common_tags

  # Optional variables
  region = var.target_region
  acl    = var.s3_acl

  bucket_policy = (var.s3_policy != ""
    ? var.s3_policy
  : data.template_file.s3-policy.rendered)

  logging             = ["${var.s3_logging}"]
  lifecycle_rule      = ["${var.s3_lifecycle_rule}"]
  acceleration_status = var.s3_acceleration_status
  force_destroy       = var.s3_force_destroy
  enable_versioning   = var.s3_enable_versioning
  enable_mfa_delete   = var.s3_enable_mfa_delete
  s3_tags             = var.s3_tags
}
