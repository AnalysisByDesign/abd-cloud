# --------------------------------------------------------------------------------------------

data "aws_caller_identity" "accepter" {
  provider = "aws.accepter"
}

data "aws_vpc" "accepter_vpc" {
  provider   = "aws.accepter"
  id         = "${var.accepter_vpc_id}"
  cidr_block = "${var.accepter_vpc_cidr}"
}

data "terraform_remote_state" "requester" {
  backend = "s3"

  config {
    encrypt  = true
    bucket   = "abd-tf-state"
    key      = "${local.vpc_tags["Account"]}/${local.vpc_tags["Name"]}/vpc.tfstate"
    region   = "eu-west-1"
    role_arn = "arn:aws:iam::813984516777:role/terraform"
  }
}

data "terraform_remote_state" "accepter" {
  backend = "s3"

  config {
    encrypt  = true
    bucket   = "abd-tf-state"
    key      = "${local.accepter_vpc_tags["Account"]}/${local.accepter_vpc_tags["Name"]}/vpc.tfstate"
    region   = "eu-west-1"
    role_arn = "arn:aws:iam::813984516777:role/terraform"
  }
}
