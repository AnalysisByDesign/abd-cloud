# --------------------------------------------------------------------------------------------
# CloudTrail
# --------------------------------------------------------------------------------------------

resource "aws_cloudtrail" "this" {
  name                          = "${var.cloudtrail_name}"
  s3_bucket_name                = "${var.s3_name}"
  s3_key_prefix                 = ""
  include_global_service_events = true
  enable_logging                = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  # TODO - Need to add encryption to the files that are stored
  # kms_key_id = ""

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
  tags       = "${merge(local.common_tags, map("Name", format("%s", var.cloudtrail_name)))}"
  depends_on = ["module.cloudtrail-s3"]
}
