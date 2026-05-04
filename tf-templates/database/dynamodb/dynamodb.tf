# --------------------------------------------------------------------------------------------
# DynamoDB Table
# --------------------------------------------------------------------------------------------

module "ec2-sg" "this" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//database/dynamodb"

  # Required variables
  name          = var.name
  common_tags   = local.common_tags
  dynamodb_tags = var.dynamodb_tags
}
