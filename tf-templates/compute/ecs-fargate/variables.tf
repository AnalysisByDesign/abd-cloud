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
#                                  ECS Fargate
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "private_app_subnets" {
  description = "A list of private subnets to be used for app resource within this deployment"
  type        = list(string)
}

variable "docker_image" {
  description = "Docker image to load from the registry"
  type        = string
}

# Optional -----------------------------------------------------------------------------------

variable "network_mode" {
  description = "The Docker networking mode - none, bridge, awsvpc or host."
  type        = string
  default     = "awsvpc"
}

variable "task_definition_cpu" {
  description = "CPU units to allocate to the tasks"
  type        = string
  default     = "256"
}

variable "task_definition_memory" {
  description = "RAM to allocate to the tasks"
  type        = string
  default     = "512"
}

variable "container_port" {
  description = "The port on the container to associate with the load balancer"
  type        = string
  default     = "80"
}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running."
  type        = string
  default     = "1"
}

variable "tasks_folder" {
  description = "Folder containing tasks templates to apply to the task definition"
  type        = string
  default     = "files"
}

variable "tasks_file" {
  description = "Task template file to apply to the task definition"
  type        = string
  default     = "task-defn.json.tpl"
}

variable "awslogs_group" {
  description = "CloudWatch group"
  type        = string
  default     = "infra"
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

