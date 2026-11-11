# ============================================================================================
# Common parameters
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "name" {
  description = "The name prefix of the various resources"
  type        = string
}

variable "rds_security_group" {
  description = "The name of the RDS security group (empty for no RDS access rules)"
  type        = string
  default     = ""
}

variable "efs_security_group" {
  description = "The name of the EFS security group (empty for no EFS access rules)"
  type        = string
  default     = ""
}

# Optional -----------------------------------------------------------------------------------

variable "r53_name" {
  description = "The name for the route53 entry"
  type        = string
  default     = ""
}

# ============================================================================================
#                                       Load Balancer
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "public_subnets" {
  description = "A list of public subnets to be used for this deployment"
  type        = list(string)
}

# Optional -----------------------------------------------------------------------------------

variable "alb_health_check_path" {
  description = "The path to test for the health-check"
  type        = string
  default     = "/"
}

variable "alb_health_check_status" {
  description = "The return code for the health-check"
  type        = string
  default     = "200,301,302"
}

variable "alb_ingress_cidr" {
  description = "The ingress CIDR range for access to the load balancer"
  type        = string
  default     = "0.0.0.0/0"
}

# ============================================================================================
#                                    launch Configuration
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "asg_ami_image_glob" {
  description = "The EC2 AMI image name to search for"
  type        = string
}

variable "asg_ami_image_owner" {
  description = "The EC2 AMI image owner"
  type        = string
}

# Optional -----------------------------------------------------------------------------------

variable "asg_ec2_instance_type" {
  description = "The EC2 instance type to build"
  type        = string
  default     = "t3.micro"
}

variable "asg_iam_profile_name" {
  description = "IAM instance profile to use for EC2 instances"
  type        = string
  default     = ""
}

variable "s3_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the S3 bucket"
  type        = string
  default     = ""
}

variable "ssm_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt SSM SecureString parameters"
  type        = string
  default     = ""
}

variable "ssm_extra_key_prefixes" {
  description = "Additional SSM parameter path prefixes to grant GetParameter access to, beyond the default /{vpc_name}/*"
  type        = list(string)
  default     = []
}

variable "ses_identity_arns" {
  description = "SES identity ARNs (verified email addresses and/or domains) that this instance role may send from via ses:SendEmail / ses:SendRawEmail"
  type        = list(string)
  default     = []
}

variable "ec2_policy_template_folder" {
  description = "Folder containing policy templates to apply to the instance roles"
  type        = string
  default     = "./files"
}

variable "ec2_policy_template" {
  description = "IAM Policy template file"
  type        = string
  default     = "s3-access-policy.tpl.json"
}

variable "user_data_script_folder" {
  description = "Folder containing user data templates to apply to the instances"
  type        = string
  default     = "./files"
}

variable "user_data_script" {
  description = "User data template file to apply to the instance"
  type        = string
  default     = "blank-user-data.tpl.sh"
}

# ============================================================================================
#                                      Key Pairs
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "asg_ssh_key_name" {
  description = "Name of SSH key to upload"
  type        = string
}

variable "asg_ssh_public_key_file" {
  description = "Physical file location of public key part to upload"
  type        = string
}

# Optional -----------------------------------------------------------------------------------

# ============================================================================================
#                                  AutoScaling Group
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "private_app_subnets" {
  description = "A list of private subnets to be used for app resource within this deployment"
  type        = list(string)
}

# Optional -----------------------------------------------------------------------------------

variable "asg_min_size" {
  description = "Minimum size of the autoscaling group"
  type        = string
  default     = "0"
}

variable "asg_desired_capacity" {
  description = "Desired size of the autoscaling group"
  type        = string
  default     = "0"
}

variable "asg_max_size" {
  description = "Maximum size of the autoscaling group"
  type        = string
  default     = "1"
}

variable "asg_default_cooldown" {
  description = "Cooldown period before allowing another autoscaling action"
  type        = string
  default     = "120"
}

variable "asg_health_check_grace_period" {
  description = "Maximum"
  type        = string
  default     = "240"
}

variable "asg_capacity_timeout" {
  description = "Maximum"
  type        = string
  default     = "600s"
}

variable "asg_force_delete" {
  description = "Force delete of autoscaling group if instances not terminating"
  type        = string
  default     = "false"
}

variable "asg_termination_policies" {
  description = "Termination policies to apply to instances"
  type        = list(string)
  default     = ["default"]
}

variable "asg_delete_timeout" {
  description = "Delete timeout setting"
  type        = string
  default     = "15m"
}

variable "asg_enable_instance_refresh" {
  description = "Automatically trigger a rolling instance refresh when the launch template changes"
  type        = bool
  default     = false
}

variable "asg_instance_refresh_min_healthy_percentage" {
  description = "Minimum percentage of instances that must remain healthy during an instance refresh"
  type        = number
  default     = 100
}

variable "asg_instance_refresh_max_healthy_percentage" {
  description = "Maximum percentage of the desired capacity in service during an instance refresh. Above 100 (with a min of 100) launches replacements before terminating the old instances"
  type        = number
  default     = 110
}

variable "asg_instance_refresh_instance_warmup" {
  description = "Seconds to wait after a new instance comes in service before moving on during an instance refresh"
  type        = number
  default     = null
}

variable "asg_instance_refresh_triggers" {
  description = "List of property name changes to trigger a refresh"
  type        = list(string)
  default     = []
}

# ============================================================================================
#                                  S3 Bucket
# ============================================================================================

variable "s3_name" {
  description = "The name of the S3 bucket for storage"
  type        = string
  default     = ""
}

# ============================================================================================
#                                  Queues
# ============================================================================================

# Optional -----------------------------------------------------------------------------------

variable "queue_name" {
  description = "Queue name"
  type        = string
  default     = ""
}

variable "queue_message_retention_seconds" {
  description = "Message retention period (seconds)"
  default     = 345600
}

variable "queue_max_message_size" {
  description = "Max message size (bytes)"
  default     = 262144
}

variable "queue_delay_seconds" {
  description = "Delivery delay in (seconds)"
  default     = 0
}

variable "queue_receive_wait_time_seconds" {
  description = "Receive wait time (seconds)"
  default     = 0
}

# ============================================================================================
#                                      End of Variable Declarations
# ============================================================================================

# ============================================================================================
#                                  Optional Features
# ============================================================================================

variable "enable_load_balancer" {
  description = "Create the ALB, its SSL certificate, DNS alias record and security groups, and use ELB health checks"
  type        = bool
  default     = true
}

variable "asg_subnet_tier" {
  description = "Which subnets the ASG launches instances into: private_app or public"
  type        = string
  default     = "private_app"

  validation {
    condition     = contains(["private_app", "public"], var.asg_subnet_tier)
    error_message = "asg_subnet_tier must be private_app or public."
  }
}

variable "asg_require_public_ip" {
  description = "Auto-assign a public IP to instances (needs asg_subnet_tier = public)"
  type        = bool
  default     = false
}

variable "asg_availability_zones" {
  description = "Restrict the ASG to subnets in these AZs (empty for every subnet in the tier)"
  type        = list(string)
  default     = []
}

variable "managed_route_table_azs" {
  description = "AZs whose private route tables (<vpc>-private-<az>) the instances manage; their IDs and ARNs reach the templates as route_table_ids and route_table_arns"
  type        = list(string)
  default     = []
}

variable "asg_scheduled_refresh_expression" {
  description = "EventBridge Scheduler expression for a recurring instance refresh, e.g. cron(0 4 ? * TUE *) (empty for none)"
  type        = string
  default     = ""
}

variable "asg_scheduled_refresh_timezone" {
  description = "Time zone for asg_scheduled_refresh_expression"
  type        = string
  default     = "Europe/London"
}

variable "asg_initial_lifecycle_hooks" {
  description = "Lifecycle hooks to create with the ASG (see the asg module's initial_lifecycle_hooks)"
  type = list(object({
    name                    = string
    lifecycle_transition    = string
    default_result          = optional(string, "ABANDON")
    heartbeat_timeout       = optional(number, 300)
    notification_metadata   = optional(string)
    notification_target_arn = optional(string)
    role_arn                = optional(string)
  }))
  default = []
}

variable "asg_ingress_cidr_blocks" {
  description = "CIDR blocks allowed all inbound traffic to the instances (empty for none)"
  type        = list(string)
  default     = []
}

variable "extra_template_vars" {
  description = "Additional variables passed to the user data and IAM policy templates"
  type        = map(string)
  default     = {}
}

variable "enable_alarms" {
  description = "Create CloudWatch alarms for no InService instances and failed status checks"
  type        = bool
  default     = false
}

variable "alerts_topic_name" {
  description = "Name of the SNS topic the alarms notify (set account-wide by the account template params)"
  type        = string
  default     = ""
}
