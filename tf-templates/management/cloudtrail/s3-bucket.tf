# --------------------------------------------------------------------------------------------
# S3
# --------------------------------------------------------------------------------------------

module "cloudtrail-s3" {
  source = "../../../../abd-cloud-modules/storage/aws-s3"

  count = var.cloudtrail_hub ? 1 : 0

  # Required variables
  name        = var.s3_name
  common_tags = local.common_tags

  # Optional variables
  region = var.target_region

  bucket_policy = templatefile("${path.module}/files/cloudtrail.json.tpl", { s3_name = var.s3_name })

  lifecycle_rule    = var.s3_lifecycle_rule
  enable_mfa_delete = "false"
  s3_tags           = var.s3_tags
}

# TODO - Need to enable MFA delete on this bucket.
# but not sure how to enable this across account within Terraform

