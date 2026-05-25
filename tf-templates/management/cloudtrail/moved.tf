# --------------------------------------------------------------------------------------------
# Moved block — count was added to module.cloudtrail-s3 during the Terraform 1.x upgrade.
# Without this, Terraform destroys the old module.cloudtrail-s3 instance and creates
# module.cloudtrail-s3[0], which cascades a destroy+create onto aws_cloudtrail.this
# via its depends_on = [module.cloudtrail-s3].
# --------------------------------------------------------------------------------------------

moved {
  from = module.cloudtrail-s3
  to   = module.cloudtrail-s3[0]
}
