# --------------------------------------------------------------------------------------------
# DynamoDB Table
# --------------------------------------------------------------------------------------------

module "ec2-sg" "this" {
  source = "../../../../abd-cloud-modules/database/dynamodb"

  # Required variables
  name          = var.name
  common_tags   = local.common_tags
  dynamodb_tags = var.dynamodb_tags
}
