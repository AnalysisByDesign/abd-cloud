# template: compute/ecs-service

One ECS service on the EC2 cluster (WP-04 ruling 5): one params target per service, `wordpress-vpc/svc.<name>`.

## Resources Provisioned

- **Task definition** `<vpc>-<name>`, built from the `containers` list (bridge mode with dynamic host ports by default, ARM64), with each container logging to the service's log group `/ecs/<vpc>/<name>` (14 days).
- **Execution role** `<vpc>-ecs-<name>-execution`: image pulls through `ecr-pull-abd` (including first pulls through the pull-through cache), its own log group, and exactly the SSM parameters the containers use as `secrets`.
- **Task role** `<vpc>-ecs-<name>-task`: nothing by default; EFS mounts through the service's own access points, ECS Exec when enabled, and any `task_role_policy_arns`.
- **ECS service**, on the cluster's default capacity provider strategy, with the deployment circuit breaker and rollback on and launch-before-stop deployments (100/200). By default CI owns the task definition revisions (`task_definition_managed_externally`, ruling 6): Terraform creates the service from the first revision, then ignores it.
- **Optional, with `hostnames`**: a target group, a host-header rule on the existing ALB's HTTPS listener at `listener_rule_priority`, alias records when `dns_zone_name` is set, and a no-healthy-targets alarm (`enable_alarms`).
- **Optional, with `efs_access_points`**: one access point per volume on the shared file system, owned by the image's user (10001:10001 by default).
- **Optional, with `scheduled_tasks`**: an EventBridge Scheduler schedule per entry running the family's latest ACTIVE revision with one container's command overridden (WP-Cron, WP-05 ruling 7), and the scheduler role `<vpc>-ecs-<name>-scheduler`, which may run only this family on this cluster and pass only this service's two roles.
- **Optional, per container `tmpfs`**: in-memory mounts (mode 1777, counted against the container's memory), e.g. the W3 Total Cache page cache (WP-05 ruling 14).
- **Optional, in `awsvpc` mode**: the task's own security group and a Cloud Map A record (`service_discovery_namespace`), as for the smtp relay.

## Notes

- The ALB, its certificates and its default action belong to other targets (`app.wordpress` and `hosted-sites`); this template only adds a target group and a rule. The ECS hosts' security group already allows the ALB in on the dynamic port range.
- CI rolls out a new image by registering a revision of the family with the new digest and updating the service, using a role from `security/github-deploy` (`ecs_deploy_roles`). A change to the task definition here registers a new revision, which the service picks up at the next rollout (or with `aws ecs update-service --force-new-deployment` after pointing it at the revision).
- Earlier revisions stay registered (`skip_destroy`), so rolling back to one is always possible.
- A scheduled task runs the latest ACTIVE revision, which is the last one CI registered. After a rollout the circuit breaker rolled back, that is the failed revision, so scheduled runs fail too until the next good rollout; the cluster's failed-task alert reports them.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.73.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_log_group"></a> [log\_group](#module\_log\_group) | ../../../../abd-cloud-modules/monitoring/cloudwatch/group | n/a |
| <a name="module_service"></a> [service](#module\_service) | ../../../../abd-cloud-modules/compute/ecs/service | n/a |
| <a name="module_task"></a> [task](#module\_task) | ../../../../abd-cloud-modules/compute/ecs/task | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_metric_alarm.no_healthy_targets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_efs_access_point.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_iam_role.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.execution_ecr_pull](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb_listener_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_scheduler_schedule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_security_group.awsvpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_service_discovery_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_vpc_security_group_egress_rule.awsvpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.awsvpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_cluster) | data source |
| [aws_efs_file_system.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/efs_file_system) | data source |
| [aws_iam_policy.ecr_pull](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.ecs_tasks_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.scheduler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.scheduler_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb) | data source |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb_listener) | data source |
| [aws_route53_zone.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_service_discovery_dns_namespace.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/service_discovery_dns_namespace) | data source |
| [aws_sns_topic.alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |
| [aws_subnet.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_acct_target"></a> [acct\_target](#input\_acct\_target) | Target AWS account to build infrastructure into | `string` | n/a | yes |
| <a name="input_acct_target_role"></a> [acct\_target\_role](#input\_acct\_target\_role) | Role in target account to assume when building infrastructure | `string` | `"terraform"` | no |
| <a name="input_alerts_topic_name"></a> [alerts\_topic\_name](#input\_alerts\_topic\_name) | SNS topic the alarms notify (set account-wide by the account template params) | `string` | `""` | no |
| <a name="input_awsvpc_ingress_cidr_blocks"></a> [awsvpc\_ingress\_cidr\_blocks](#input\_awsvpc\_ingress\_cidr\_blocks) | awsvpc only: CIDR blocks allowed in to the task on awsvpc\_ingress\_ports | `list(string)` | `[]` | no |
| <a name="input_awsvpc_ingress_ports"></a> [awsvpc\_ingress\_ports](#input\_awsvpc\_ingress\_ports) | awsvpc only: TCP ports open to awsvpc\_ingress\_cidr\_blocks | `list(number)` | `[]` | no |
| <a name="input_capacity_provider_strategy"></a> [capacity\_provider\_strategy](#input\_capacity\_provider\_strategy) | Capacity provider strategy; empty uses the cluster's default strategy | <pre>list(object({<br/>    capacity_provider = string<br/>    weight            = optional(number, 1)<br/>    base              = optional(number, 0)<br/>  }))</pre> | `[]` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | ECS cluster the service runs in (e.g. abd-wordpress-cluster) | `string` | n/a | yes |
| <a name="input_common_tag_component"></a> [common\_tag\_component](#input\_common\_tag\_component) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_environment"></a> [common\_tag\_environment](#input\_common\_tag\_environment) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_owner"></a> [common\_tag\_owner](#input\_common\_tag\_owner) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_project"></a> [common\_tag\_project](#input\_common\_tag\_project) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_subsystem"></a> [common\_tag\_subsystem](#input\_common\_tag\_subsystem) | n/a | `string` | n/a | yes |
| <a name="input_containers"></a> [containers](#input\_containers) | Containers in the task. image is a full image reference (CI later pins it by digest).<br/>port is the container port (bridge mode maps it to a dynamic host port). secrets maps an<br/>environment variable to an SSM parameter name (e.g. /abd-wordpress/hello/token); the<br/>execution role can read exactly those parameters. mount\_points refer to efs\_access\_points<br/>keys. Logs go to the service's log group with the container name as the stream prefix.<br/>tmpfs mounts are in memory, mode 1777, and count against the container's memory. | <pre>list(object({<br/>    name                     = string<br/>    image                    = string<br/>    essential                = optional(bool, true)<br/>    cpu                      = optional(number, 0)<br/>    memory                   = optional(number)<br/>    memory_reservation       = optional(number)<br/>    port                     = optional(number)<br/>    command                  = optional(list(string))<br/>    entry_point              = optional(list(string))<br/>    environment              = optional(map(string), {})<br/>    secrets                  = optional(map(string), {})<br/>    user                     = optional(string)<br/>    readonly_root_filesystem = optional(bool)<br/>    stop_timeout             = optional(number)<br/>    mount_points = optional(list(object({<br/>      source_volume  = string<br/>      container_path = string<br/>      read_only      = optional(bool, false)<br/>    })), [])<br/>    tmpfs = optional(list(object({<br/>      container_path = string<br/>      size_mib       = number<br/>    })), [])<br/>    health_check = optional(object({<br/>      command      = list(string)<br/>      interval     = optional(number, 30)<br/>      timeout      = optional(number, 5)<br/>      retries      = optional(number, 3)<br/>      start_period = optional(number, 0)<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_cpu_architecture"></a> [cpu\_architecture](#input\_cpu\_architecture) | ARM64 or X86\_64; the task only places on hosts of that architecture | `string` | `"ARM64"` | no |
| <a name="input_deployment_maximum_percent"></a> [deployment\_maximum\_percent](#input\_deployment\_maximum\_percent) | Upper limit on running tasks during a deployment | `number` | `200` | no |
| <a name="input_deployment_minimum_healthy_percent"></a> [deployment\_minimum\_healthy\_percent](#input\_deployment\_minimum\_healthy\_percent) | Lower limit on healthy tasks during a deployment (100 starts the new task before stopping the old) | `number` | `100` | no |
| <a name="input_deregistration_delay"></a> [deregistration\_delay](#input\_deregistration\_delay) | Seconds the target group drains a stopping task before deregistering it | `number` | `30` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Number of tasks to keep running | `number` | `1` | no |
| <a name="input_dns_zone_name"></a> [dns\_zone\_name](#input\_dns\_zone\_name) | Public hosted zone to create alias records for the host names in, pointing at the ALB (empty when the hosted-sites targets own the DNS) | `string` | `""` | no |
| <a name="input_ecr_pull_policy_name"></a> [ecr\_pull\_policy\_name](#input\_ecr\_pull\_policy\_name) | Managed policy giving the execution role ECR pulls, including first pulls through the pull-through cache (WP-02) | `string` | `"ecr-pull-abd"` | no |
| <a name="input_efs_access_points"></a> [efs\_access\_points](#input\_efs\_access\_points) | EFS access points, keyed by volume name. Each presents path as the root, owned by uid:gid (created with permissions when missing), and the containers mount it by key in mount\_points. The task role is allowed to mount (and write unless read\_only) through these access points only | <pre>map(object({<br/>    path        = string<br/>    uid         = optional(number, 10001)<br/>    gid         = optional(number, 10001)<br/>    permissions = optional(string, "0755")<br/>    read_only   = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_efs_file_system_name"></a> [efs\_file\_system\_name](#input\_efs\_file\_system\_name) | Name tag of the EFS file system the access points are on | `string` | `"abd-wordpress-html"` | no |
| <a name="input_enable_alarms"></a> [enable\_alarms](#input\_enable\_alarms) | Alarm when the target group has no healthy targets (needs a load balancer) | `bool` | `false` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Allow ECS Exec into the containers (adds the SSM messages permissions to the task role) | `bool` | `false` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Seconds ECS ignores failing load balancer health checks after a task starts | `number` | `60` | no |
| <a name="input_health_check_matcher"></a> [health\_check\_matcher](#input\_health\_check\_matcher) | HTTP codes that count as healthy | `string` | `"200-399"` | no |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | Target group health check path | `string` | `"/"` | no |
| <a name="input_hostnames"></a> [hostnames](#input\_hostnames) | Host names routed to the service by a listener rule on the existing ALB (empty for no load balancer) | `list(string)` | `[]` | no |
| <a name="input_listener_rule_priority"></a> [listener\_rule\_priority](#input\_listener\_rule\_priority) | Listener rule priority, unique on the listener (bands: 100s WordPress, 200s Tulox, 900s tests; WP-04 ruling 12) | `number` | `null` | no |
| <a name="input_load_balancer_container"></a> [load\_balancer\_container](#input\_load\_balancer\_container) | Container (and its port) the target group sends traffic to; defaults to the first container | `string` | `""` | no |
| <a name="input_load_balancer_name"></a> [load\_balancer\_name](#input\_load\_balancer\_name) | The existing ALB, by name without the VPC prefix | `string` | `"ec2-asg"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Days to keep the service's logs (WP-04 ruling 10) | `number` | `14` | no |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Service name (e.g. hello). Resources are named <vpc>-<name>, and the log group /ecs/<vpc>/<name> | `string` | n/a | yes |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | bridge (dynamic host ports, the default) or awsvpc (one ENI per task, needed for a Cloud Map A record) | `string` | `"bridge"` | no |
| <a name="input_ordered_placement_strategy"></a> [ordered\_placement\_strategy](#input\_ordered\_placement\_strategy) | Task placement strategies, in order. The default spreads tasks across AZs, then packs by memory | <pre>list(object({<br/>    type  = string<br/>    field = optional(string)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "field": "attribute:ecs.availability-zone",<br/>    "type": "spread"<br/>  },<br/>  {<br/>    "field": "memory",<br/>    "type": "binpack"<br/>  }<br/>]</pre> | no |
| <a name="input_private_app_subnets"></a> [private\_app\_subnets](#input\_private\_app\_subnets) | awsvpc only: the private app subnet CIDRs the tasks run in (set by the VPC params) | `list(string)` | `[]` | no |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_scheduled_tasks"></a> [scheduled\_tasks](#input\_scheduled\_tasks) | One-off tasks EventBridge Scheduler runs on a schedule, keyed by a short name (e.g. wp-cron). Each runs the service's task definition family (its latest ACTIVE revision) with one container's command overridden (any other containers start as usual). schedule is an EventBridge Scheduler expression, e.g. rate(5 minutes) | <pre>map(object({<br/>    schedule  = string<br/>    container = string<br/>    command   = list(string)<br/>    timezone  = optional(string, "Europe/London")<br/>  }))</pre> | `{}` | no |
| <a name="input_service_discovery_name"></a> [service\_discovery\_name](#input\_service\_discovery\_name) | awsvpc only: record name in the namespace; defaults to the service name | `string` | `""` | no |
| <a name="input_service_discovery_namespace"></a> [service\_discovery\_namespace](#input\_service\_discovery\_namespace) | awsvpc only: Cloud Map namespace to register an A record in (e.g. abd-wordpress.internal), as <service\_discovery\_name>.<namespace>; empty for none | `string` | `""` | no |
| <a name="input_target_group_name"></a> [target\_group\_name](#input\_target\_group\_name) | Target group name (32 characters at most); defaults to <vpc>-<name> | `string` | `""` | no |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |
| <a name="input_task_definition_managed_externally"></a> [task\_definition\_managed\_externally](#input\_task\_definition\_managed\_externally) | CI registers new revisions and updates the service, so Terraform ignores task\_definition after creating the service (WP-04 ruling 6) | `bool` | `true` | no |
| <a name="input_task_role_policy_arns"></a> [task\_role\_policy\_arns](#input\_task\_role\_policy\_arns) | Managed policies to attach to the task role (what the containers can call in AWS) | `list(string)` | `[]` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The VPC CIDR range to extract | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC id to extract | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_execution_role_arn"></a> [execution\_role\_arn](#output\_execution\_role\_arn) | Execution role (CI must be allowed to pass it) |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | The service's log group |
| <a name="output_service_discovery_name"></a> [service\_discovery\_name](#output\_service\_discovery\_name) | Cloud Map DNS name (null without service discovery) |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | The ECS service's name |
| <a name="output_target_group_arn"></a> [target\_group\_arn](#output\_target\_group\_arn) | Target group (null without a load balancer) |
| <a name="output_task_definition_family"></a> [task\_definition\_family](#output\_task\_definition\_family) | Task definition family; CI registers new revisions of it |
| <a name="output_task_role_arn"></a> [task\_role\_arn](#output\_task\_role\_arn) | Task role (CI must be allowed to pass it) |
<!-- END_TF_DOCS -->
