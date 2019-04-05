# --------------------------------------------------------------------------------------------
# S3
# --------------------------------------------------------------------------------------------

data "template_file" "s3-policy" {
  template = "${file("./files/cloudtrail.json.tpl")}"

  vars {
    s3_name       = "${var.s3_name}"
    target_region = "${var.target_region}"
  }
}

module "cloudtrail-s3" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//storage/aws-s3"

  count = "${var.cloudtrail_hub ? 1 : 0}"

  # Required variables
  name        = "${var.s3_name}-${var.target_region}"
  common_tags = "${local.common_tags}"

  # Optional variables
  region = "${var.target_region}"

  bucket_policy = "${data.template_file.s3-policy.rendered}"

  lifecycle_rule    = ["${var.s3_lifecycle_rule}"]
  enable_mfa_delete = "false"
  s3_tags           = "${var.s3_tags}"
}

# TODO - Need to enable MFA delete on this bucket.
# but not sure how to enable this across account within Terraform

