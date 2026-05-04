# --------------------------------------------------------------------------------------------
# Queues
# --------------------------------------------------------------------------------------------

# We need the option to build the queues in Ireland due to a FIFO requirement
# When FIFO comes to London, this provider and relevant other code can be removed

provider "aws" {
  alias   = "queue-special-region"
  version = "~> 1.48"

  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::${var.acct_target}:role/${var.acct_target_role == ""
      ? "terraform"
    : var.acct_target_role}"
  }
}

# --------------------------------------------------------------------------------------------
# Dead-letter-queue
# --------------------------------------------------------------------------------------------

module "queue-dead-letter" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//integrate/queue"

  # As we require the queues to be in Ireland for FIFO, we need this
  providers = {
    aws = "aws.queue-special-region"
  }

  count = var.queue_name != "" ? 1 : 0
  name = (format("%s-%s-dead-letter.fifo", local.vpc_name,
  (var.queue_name != "" ? var.queue_name : var.name)))

  fifo                      = true
  delay_seconds             = var.queue_delay_seconds
  max_message_size          = var.queue_max_message_size
  message_retention_seconds = var.queue_message_retention_seconds
  receive_wait_time_seconds = var.queue_receive_wait_time_seconds

  common_tags = local.common_tags
}

# --------------------------------------------------------------------------------------------
# Queue
# --------------------------------------------------------------------------------------------

module "queue" {
  source = "git@github.com:AnalysisByDesign/abd-cloud-modules.git//integrate/queue"

  # As we require the queues to be in Ireland for FIFO, we need this
  providers = {
    aws = "aws.queue-special-region"
  }

  count = var.queue_name != "" ? 1 : 0
  name = (format("%s-%s.fifo", local.vpc_name,
  (var.queue_name != "" ? var.queue_name : var.name)))

  fifo                      = true
  delay_seconds             = var.queue_delay_seconds
  max_message_size          = var.queue_max_message_size
  message_retention_seconds = var.queue_message_retention_seconds
  receive_wait_time_seconds = var.queue_receive_wait_time_seconds
  deadletter_enable         = true
  deadletter_arn            = module.queue-dead-letter.arn

  common_tags = local.common_tags
}
