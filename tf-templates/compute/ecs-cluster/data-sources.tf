# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

# Host ASGs that exist so far. The plural data source returns only those found, so a
# capacity provider appears on the first apply after its ASG is built.
data "aws_autoscaling_groups" "hosts" {
  names = [for k in keys(var.capacity_providers) : format("%s-%s", local.vpc_name, k)]
}

locals {
  # Name taken from each ARN, rather than relying on the names and arns lists sharing an order
  host_asg_arns = {
    for arn in data.aws_autoscaling_groups.hosts.arns :
    regex("autoScalingGroupName/(.+)$", arn)[0] => arn
  }

  # Keyed by the full ASG name, which is also the capacity provider's name
  capacity_providers = {
    for k, v in var.capacity_providers : format("%s-%s", local.vpc_name, k) => v
    if contains(keys(local.host_asg_arns), format("%s-%s", local.vpc_name, k))
  }
}

data "aws_sns_topic" "alerts" {
  count = var.enable_alerts ? 1 : 0
  name  = var.alerts_topic_name
}
