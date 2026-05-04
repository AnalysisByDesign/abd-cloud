# --------------------------------------------------------------------------------------------
# Common VPC Data Source Configurations
# --------------------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "The VPC CIDR range to extract"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "The VPC id to extract"
  type        = string
  default     = ""
}

# --------------------------------------------------------------------------------------------

data "aws_vpc" "vpc" {
  count      = var.vpc_cidr != "None" ? 1 : 0
  id         = var.vpc_id
  cidr_block = var.vpc_cidr
}

# --------------------------------------------------------------------------------------------

locals {
  vpc_id   = data.aws_vpc.vpc.id
  vpc_name = data.aws_vpc.vpc.tags["Name"]
  vpc_cidr = data.aws_vpc.vpc.cidr_block
  vpc_tags = data.aws_vpc.vpc.tags
}
