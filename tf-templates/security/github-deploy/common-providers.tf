# --------------------------------------------------------------------------------------------
# Prepare the connectivity and configs
# --------------------------------------------------------------------------------------------

# Required Variables -------------------------------------------------------------------------

variable "acct_target" {
  description = "Target AWS account to build infrastructure into"
  type        = string
}

# Optional Variables -------------------------------------------------------------------------

variable "acct_target_role" {
  description = "Role in target account to assume when building infrastructure"
  type        = string
  default     = "terraform"
}

variable "target_region" {
  description = "The default region to build infrastructure in"
  type        = string
  default     = "eu-west-1"
}

# -------------------------------------------------------------------------------------------

terraform {
  required_version = "~> 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    encrypt      = true
    use_lockfile = true
    region       = "eu-west-1"
  }
}

provider "aws" {
  region = var.target_region

  assume_role {
    role_arn = "arn:aws:iam::${var.acct_target}:role/${var.acct_target_role}"
  }
}

# --------------------------------------------------------------------------------------------
