# template: compute/ecs-cluster

Provisions the ECS cluster for EC2-hosted container workloads (WP-04), with its capacity providers, a Cloud Map namespace and failure alerts.

## Resources Provisioned

- **ECS cluster** named `<vpc>-<name>` (e.g. `abd-wordpress-cluster`), with Container Insights set by `ecs_insights` (default `disabled`).
- **Capacity providers**, one per host ASG listed in `capacity_providers`, with managed scaling, managed termination protection and managed draining, plus the cluster's default strategy.
- **Cloud Map private DNS namespace** (optional, `service_discovery_namespace`) for services in `awsvpc` mode.
- **EventBridge rule** (optional, `enable_alerts`) sending deployment failures, placement failures and tasks that fail to start or whose essential container exits to the alerts SNS topic. The topic's policy must allow EventBridge (`alerts_allow_eventbridge` in the `account` template).

## Apply order

The host ASGs are built by `compute/ec2-asg` targets (with `ecs_cluster_name` set), and their instances register with the cluster at boot, so the cluster comes first. A capacity provider is only created once its ASG exists, so: apply this target, then the hosts, then this target again. Repeat the second apply whenever a host ASG is added.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.48.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_ecs-cluster"></a> [ecs-cluster](#module\_ecs-cluster) | ../../../../abd-cloud-modules/compute/ecs/cluster | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_event_rule.ecs_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.ecs_alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_service_discovery_private_dns_namespace.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_autoscaling_groups.hosts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/autoscaling_groups) | data source |
| [aws_sns_topic.alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_acct_target"></a> [acct\_target](#input\_acct\_target) | Target AWS account to build infrastructure into | `string` | n/a | yes |
| <a name="input_acct_target_role"></a> [acct\_target\_role](#input\_acct\_target\_role) | Role in target account to assume when building infrastructure | `string` | `"terraform"` | no |
| <a name="input_alerts_topic_name"></a> [alerts\_topic\_name](#input\_alerts\_topic\_name) | Name of the SNS topic the alerts go to (set account-wide by the account template params) | `string` | `""` | no |
| <a name="input_capacity_providers"></a> [capacity\_providers](#input\_capacity\_providers) | EC2 capacity providers, keyed by the host ASG's name without the VPC prefix (e.g. ecs-hosts for <vpc>-ecs-hosts). The provider takes the ASG's full name. A provider is only created once its ASG exists, so the cluster can be applied before the hosts and again after. base and weight set the cluster's default strategy; include\_in\_default = false leaves a provider out of it (e.g. spot) | <pre>map(object({<br/>    include_in_default        = optional(bool, true)<br/>    base                      = optional(number, 0)<br/>    weight                    = optional(number, 1)<br/>    target_capacity           = optional(number, 100)<br/>    maximum_scaling_step_size = optional(number, 1)<br/>    instance_warmup_period    = optional(number, 300)<br/>  }))</pre> | `{}` | no |
| <a name="input_common_tag_component"></a> [common\_tag\_component](#input\_common\_tag\_component) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_environment"></a> [common\_tag\_environment](#input\_common\_tag\_environment) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_owner"></a> [common\_tag\_owner](#input\_common\_tag\_owner) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_project"></a> [common\_tag\_project](#input\_common\_tag\_project) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_subsystem"></a> [common\_tag\_subsystem](#input\_common\_tag\_subsystem) | n/a | `string` | n/a | yes |
| <a name="input_ecs_insights"></a> [ecs\_insights](#input\_ecs\_insights) | Container Insights: disabled, enabled or enhanced | `string` | `"disabled"` | no |
| <a name="input_enable_alerts"></a> [enable\_alerts](#input\_enable\_alerts) | Send ECS deployment failures, placement failures and failed tasks to the alerts topic (its policy must allow EventBridge) | `bool` | `false` | no |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | The name prefix of the various resources | `string` | n/a | yes |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_service_discovery_namespace"></a> [service\_discovery\_namespace](#input\_service\_discovery\_namespace) | Cloud Map private DNS namespace for the VPC, e.g. abd-wordpress.internal (empty for none) | `string` | `""` | no |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The VPC CIDR range to extract | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC id to extract | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_capacity_provider_names"></a> [capacity\_provider\_names](#output\_capacity\_provider\_names) | Capacity providers created so far (one per host ASG that exists) |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The ECS cluster's ARN |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | The ECS cluster's name |
| <a name="output_service_discovery_namespace_id"></a> [service\_discovery\_namespace\_id](#output\_service\_discovery\_namespace\_id) | The Cloud Map namespace ID (null when there is none) |
<!-- END_TF_DOCS -->
