# ============================================================================================
# Common parameters
# ============================================================================================

# Required -----------------------------------------------------------------------------------

variable "name" {
  description = "The name prefix of the various resources"
  type        = string
}

# Optional -----------------------------------------------------------------------------------

variable "ecs_insights" {
  description = "Container Insights: disabled, enabled or enhanced"
  type        = string
  default     = "disabled"
}

variable "capacity_providers" {
  description = "EC2 capacity providers, keyed by the host ASG's name without the VPC prefix (e.g. ecs-hosts for <vpc>-ecs-hosts). The provider takes the ASG's full name. A provider is only created once its ASG exists, so the cluster can be applied before the hosts and again after. base and weight set the cluster's default strategy; include_in_default = false leaves a provider out of it (e.g. spot)"
  type = map(object({
    include_in_default        = optional(bool, true)
    base                      = optional(number, 0)
    weight                    = optional(number, 1)
    target_capacity           = optional(number, 100)
    maximum_scaling_step_size = optional(number, 1)
    instance_warmup_period    = optional(number, 300)
  }))
  default = {}
}

variable "service_discovery_namespace" {
  description = "Cloud Map private DNS namespace for the VPC, e.g. abd-wordpress.internal (empty for none)"
  type        = string
  default     = ""
}

variable "enable_alerts" {
  description = "Send ECS deployment failures, placement failures and failed tasks to the alerts topic (its policy must allow EventBridge)"
  type        = bool
  default     = false
}

variable "alerts_topic_name" {
  description = "Name of the SNS topic the alerts go to (set account-wide by the account template params)"
  type        = string
  default     = ""
}
