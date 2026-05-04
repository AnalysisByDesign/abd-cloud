# ============================================================================================
# Common parameters
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "name" {
  description = "The name prefix of the various resources"
  type        = string
}

variable "rds_security_group" {
  description = "The name of the RDS security group"
  type        = string
}

variable "efs_security_group" {
  description = "The name of the EFS security group"
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

