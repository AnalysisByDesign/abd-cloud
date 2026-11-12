# ============================================================================================
# Service
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "name" {
  description = "Service name (e.g. hello). Resources are named <vpc>-<name>, and the log group /ecs/<vpc>/<name>"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster the service runs in (e.g. abd-wordpress-cluster)"
  type        = string
}

variable "containers" {
  description = <<-EOT
    Containers in the task. image is a full image reference (CI later pins it by digest).
    port is the container port (bridge mode maps it to a dynamic host port). secrets maps an
    environment variable to an SSM parameter name (e.g. /abd-wordpress/hello/token); the
    execution role can read exactly those parameters. mount_points refer to efs_access_points
    keys. Logs go to the service's log group with the container name as the stream prefix.
    tmpfs mounts are in memory, mode 1777, and count against the container's memory.
  EOT
  type = list(object({
    name                     = string
    image                    = string
    essential                = optional(bool, true)
    cpu                      = optional(number, 0)
    memory                   = optional(number)
    memory_reservation       = optional(number)
    port                     = optional(number)
    command                  = optional(list(string))
    entry_point              = optional(list(string))
    environment              = optional(map(string), {})
    secrets                  = optional(map(string), {})
    user                     = optional(string)
    readonly_root_filesystem = optional(bool)
    stop_timeout             = optional(number)
    mount_points = optional(list(object({
      source_volume  = string
      container_path = string
      read_only      = optional(bool, false)
    })), [])
    tmpfs = optional(list(object({
      container_path = string
      size_mib       = number
    })), [])
    health_check = optional(object({
      command      = list(string)
      interval     = optional(number, 30)
      timeout      = optional(number, 5)
      retries      = optional(number, 3)
      start_period = optional(number, 0)
    }))
  }))
}

# Optional -----------------------------------------------------------------------------------

variable "network_mode" {
  description = "bridge (dynamic host ports, the default) or awsvpc (one ENI per task, needed for a Cloud Map A record)"
  type        = string
  default     = "bridge"

  validation {
    condition     = contains(["bridge", "awsvpc"], var.network_mode)
    error_message = "network_mode must be bridge or awsvpc."
  }
}

variable "cpu_architecture" {
  description = "ARM64 or X86_64; the task only places on hosts of that architecture"
  type        = string
  default     = "ARM64"
}

variable "desired_count" {
  description = "Number of tasks to keep running"
  type        = number
  default     = 1
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit on healthy tasks during a deployment (100 starts the new task before stopping the old)"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Upper limit on running tasks during a deployment"
  type        = number
  default     = 200
}

variable "task_definition_managed_externally" {
  description = "CI registers new revisions and updates the service, so Terraform ignores task_definition after creating the service (WP-04 ruling 6)"
  type        = bool
  default     = true
}

variable "capacity_provider_strategy" {
  description = "Capacity provider strategy; empty uses the cluster's default strategy"
  type = list(object({
    capacity_provider = string
    weight            = optional(number, 1)
    base              = optional(number, 0)
  }))
  default = []
}

variable "ordered_placement_strategy" {
  description = "Task placement strategies, in order. The default spreads tasks across AZs, then packs by memory"
  type = list(object({
    type  = string
    field = optional(string)
  }))
  default = [
    { type = "spread", field = "attribute:ecs.availability-zone" },
    { type = "binpack", field = "memory" },
  ]
}

variable "enable_execute_command" {
  description = "Allow ECS Exec into the containers (adds the SSM messages permissions to the task role)"
  type        = bool
  default     = false
}

variable "task_role_policy_arns" {
  description = "Managed policies to attach to the task role (what the containers can call in AWS)"
  type        = list(string)
  default     = []
}

variable "ecr_pull_policy_name" {
  description = "Managed policy giving the execution role ECR pulls, including first pulls through the pull-through cache (WP-02)"
  type        = string
  default     = "ecr-pull-abd"
}

variable "log_retention_days" {
  description = "Days to keep the service's logs (WP-04 ruling 10)"
  type        = number
  default     = 14
}

# ============================================================================================
# Load balancer (optional): a target group and a host-header rule on the existing ALB
# ============================================================================================

variable "hostnames" {
  description = "Host names routed to the service by a listener rule on the existing ALB (empty for no load balancer)"
  type        = list(string)
  default     = []
}

variable "listener_rule_priority" {
  description = "Listener rule priority, unique on the listener (bands: 100s WordPress, 200s Tulox, 900s tests; WP-04 ruling 12)"
  type        = number
  default     = null
}

variable "load_balancer_name" {
  description = "The existing ALB, by name without the VPC prefix"
  type        = string
  default     = "ec2-asg"
}

variable "load_balancer_container" {
  description = "Container (and its port) the target group sends traffic to; defaults to the first container"
  type        = string
  default     = ""
}

variable "target_group_name" {
  description = "Target group name (32 characters at most); defaults to <vpc>-<name>"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Target group health check path"
  type        = string
  default     = "/"
}

variable "health_check_matcher" {
  description = "HTTP codes that count as healthy"
  type        = string
  default     = "200-399"
}

variable "health_check_grace_period_seconds" {
  description = "Seconds ECS ignores failing load balancer health checks after a task starts"
  type        = number
  default     = 60
}

variable "deregistration_delay" {
  description = "Seconds the target group drains a stopping task before deregistering it"
  type        = number
  default     = 30
}

variable "dns_zone_name" {
  description = "Public hosted zone to create alias records for the host names in, pointing at the ALB (empty when the hosted-sites targets own the DNS)"
  type        = string
  default     = ""
}

# ============================================================================================
# EFS (optional): one access point per entry on the shared file system
# ============================================================================================

variable "efs_file_system_name" {
  description = "Name tag of the EFS file system the access points are on"
  type        = string
  default     = "abd-wordpress-html"
}

variable "efs_access_points" {
  description = "EFS access points, keyed by volume name. Each presents path as the root, owned by uid:gid (created with permissions when missing), and the containers mount it by key in mount_points. The task role is allowed to mount (and write unless read_only) through these access points only"
  type = map(object({
    path        = string
    uid         = optional(number, 10001)
    gid         = optional(number, 10001)
    permissions = optional(string, "0755")
    read_only   = optional(bool, false)
  }))
  default = {}
}

# ============================================================================================
# awsvpc mode (optional): own security group and a Cloud Map A record
# ============================================================================================

variable "awsvpc_ingress_cidr_blocks" {
  description = "awsvpc only: CIDR blocks allowed in to the task on awsvpc_ingress_ports"
  type        = list(string)
  default     = []
}

variable "awsvpc_ingress_ports" {
  description = "awsvpc only: TCP ports open to awsvpc_ingress_cidr_blocks"
  type        = list(number)
  default     = []
}

variable "service_discovery_namespace" {
  description = "awsvpc only: Cloud Map namespace to register an A record in (e.g. abd-wordpress.internal), as <service_discovery_name>.<namespace>; empty for none"
  type        = string
  default     = ""
}

variable "service_discovery_name" {
  description = "awsvpc only: record name in the namespace; defaults to the service name"
  type        = string
  default     = ""
}

# ============================================================================================
# Alarms
# ============================================================================================

variable "enable_alarms" {
  description = "Alarm when the target group has no healthy targets (needs a load balancer)"
  type        = bool
  default     = false
}

variable "alerts_topic_name" {
  description = "SNS topic the alarms notify (set account-wide by the account template params)"
  type        = string
  default     = ""
}

variable "private_app_subnets" {
  description = "awsvpc only: the private app subnet CIDRs the tasks run in (set by the VPC params)"
  type        = list(string)
  default     = []
}

variable "scheduled_tasks" {
  description = "One-off tasks EventBridge Scheduler runs on a schedule, keyed by a short name (e.g. wp-cron). Each runs the service's task definition family (its latest ACTIVE revision) with one container's command overridden (any other containers start as usual). schedule is an EventBridge Scheduler expression, e.g. rate(5 minutes)"
  type = map(object({
    schedule  = string
    container = string
    command   = list(string)
    timezone  = optional(string, "Europe/London")
  }))
  default = {}
}
