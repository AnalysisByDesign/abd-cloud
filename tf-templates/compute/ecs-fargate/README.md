# template: compute/ecs-fargate

Provisions a complete ECS Fargate application tier: task definition, ECS service, Application Load Balancer, SSL certificate, Route53 DNS record, SQS queue, security groups, and a task IAM role.

## Resources Provisioned

- **ECS task definition** — Container definitions rendered from a JSON template file; CPU, memory, and IAM roles configurable
- **ECS service** — Desired count, Fargate network configuration (subnets, security groups), and ALB target group attachment
- **ALB** — Internet-facing with HTTPS listener, HTTP redirect, and target group
- **SSL certificate** — ACM certificate validated via Route53 DNS records
- **Route53** — Alias record from the application domain to the ALB
- **SQS** — Application event queue with optional DLQ
- **Security groups** — ALB and ECS task security groups with inter-tier rules
- **IAM** — Task execution role (for ECR pull and CloudWatch log write) and task role (for application-level AWS access)

## Notes

- The task container definitions are rendered from `var.tasks_folder/var.tasks_file` via `templatefile()`. The template receives `container_name`, `docker_image`, `aws_region`, `log_group`, and `sqs_queue_url`.
- Fargate requires `awsvpc` network mode; the service receives an ENI directly and security groups are applied at the task level, not the host level.

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
| <a name="module_alb-ecs-sgr"></a> [alb-ecs-sgr](#module\_alb-ecs-sgr) | ../../../../abd-cloud-modules/security/security-group-rule-link | n/a |
| <a name="module_alb-sg"></a> [alb-sg](#module\_alb-sg) | ../../../../abd-cloud-modules/security/security-group | n/a |
| <a name="module_alb-sgr-http-in"></a> [alb-sgr-http-in](#module\_alb-sgr-http-in) | ../../../../abd-cloud-modules/security/security-group-rule-cidr | n/a |
| <a name="module_alb-sgr-https-in"></a> [alb-sgr-https-in](#module\_alb-sgr-https-in) | ../../../../abd-cloud-modules/security/security-group-rule-cidr | n/a |
| <a name="module_dns_apex"></a> [dns\_apex](#module\_dns\_apex) | ../../../../abd-cloud-modules/network/dns/alias-record | n/a |
| <a name="module_ecs-alb-sgr"></a> [ecs-alb-sgr](#module\_ecs-alb-sgr) | ../../../../abd-cloud-modules/security/security-group-rule-link | n/a |
| <a name="module_ecs-http-sgr"></a> [ecs-http-sgr](#module\_ecs-http-sgr) | ../../../../abd-cloud-modules/security/security-group-rule-cidr | n/a |
| <a name="module_ecs-https-sgr"></a> [ecs-https-sgr](#module\_ecs-https-sgr) | ../../../../abd-cloud-modules/security/security-group-rule-cidr | n/a |
| <a name="module_ecs-rds-sgr"></a> [ecs-rds-sgr](#module\_ecs-rds-sgr) | ../../../../abd-cloud-modules/security/security-group-rule-link | n/a |
| <a name="module_ecs-sg"></a> [ecs-sg](#module\_ecs-sg) | ../../../../abd-cloud-modules/security/security-group | n/a |
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | ../../../../abd-cloud-modules/compute/ecs/cluster | n/a |
| <a name="module_ecs_role"></a> [ecs\_role](#module\_ecs\_role) | ../../../../abd-cloud-modules/security/iam-role | n/a |
| <a name="module_ecs_service"></a> [ecs\_service](#module\_ecs\_service) | ../../../../abd-cloud-modules/compute/ecs/service | n/a |
| <a name="module_ecs_task_definitions"></a> [ecs\_task\_definitions](#module\_ecs\_task\_definitions) | ../../../../abd-cloud-modules/compute/ecs/task | n/a |
| <a name="module_load_balancer"></a> [load\_balancer](#module\_load\_balancer) | ../../../../abd-cloud-modules/compute/alb | n/a |
| <a name="module_queue"></a> [queue](#module\_queue) | ../../../../abd-cloud-modules/integrate/queue | n/a |
| <a name="module_queue-dead-letter"></a> [queue-dead-letter](#module\_queue-dead-letter) | ../../../../abd-cloud-modules/integrate/queue | n/a |
| <a name="module_rds-ecs-sgr"></a> [rds-ecs-sgr](#module\_rds-ecs-sgr) | ../../../../abd-cloud-modules/security/security-group-rule-link | n/a |
| <a name="module_ssl_cert"></a> [ssl\_cert](#module\_ssl\_cert) | ../../../../abd-cloud-modules/security/ssl-certs | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy_document.ecs_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_subnet.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnet.lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_acct_target"></a> [acct\_target](#input\_acct\_target) | Target AWS account to build infrastructure into | `string` | n/a | yes |
| <a name="input_acct_target_role"></a> [acct\_target\_role](#input\_acct\_target\_role) | Role in target account to assume when building infrastructure | `string` | `"terraform"` | no |
| <a name="input_alb_health_check_path"></a> [alb\_health\_check\_path](#input\_alb\_health\_check\_path) | The path to test for the health-check | `string` | `"/"` | no |
| <a name="input_alb_health_check_status"></a> [alb\_health\_check\_status](#input\_alb\_health\_check\_status) | The return code for the health-check | `string` | `"200,301,302"` | no |
| <a name="input_alb_ingress_cidr"></a> [alb\_ingress\_cidr](#input\_alb\_ingress\_cidr) | The ingress CIDR range for access to the load balancer | `string` | `"0.0.0.0/0"` | no |
| <a name="input_awslogs_group"></a> [awslogs\_group](#input\_awslogs\_group) | CloudWatch group | `string` | `"infra"` | no |
| <a name="input_common_tag_component"></a> [common\_tag\_component](#input\_common\_tag\_component) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_environment"></a> [common\_tag\_environment](#input\_common\_tag\_environment) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_owner"></a> [common\_tag\_owner](#input\_common\_tag\_owner) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_project"></a> [common\_tag\_project](#input\_common\_tag\_project) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_subsystem"></a> [common\_tag\_subsystem](#input\_common\_tag\_subsystem) | n/a | `string` | n/a | yes |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | The port on the container to associate with the load balancer | `string` | `"80"` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | The number of instances of the task definition to place and keep running. | `string` | `"1"` | no |
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Docker image to load from the registry | `string` | n/a | yes |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | The name prefix of the various resources | `string` | n/a | yes |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | The Docker networking mode - none, bridge, awsvpc or host. | `string` | `"awsvpc"` | no |
| <a name="input_private_app_subnets"></a> [private\_app\_subnets](#input\_private\_app\_subnets) | A list of private subnets to be used for app resource within this deployment | `list(string)` | n/a | yes |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of public subnets to be used for this deployment | `list(string)` | n/a | yes |
| <a name="input_queue_delay_seconds"></a> [queue\_delay\_seconds](#input\_queue\_delay\_seconds) | Delivery delay in (seconds) | `number` | `0` | no |
| <a name="input_queue_max_message_size"></a> [queue\_max\_message\_size](#input\_queue\_max\_message\_size) | Max message size (bytes) | `number` | `262144` | no |
| <a name="input_queue_message_retention_seconds"></a> [queue\_message\_retention\_seconds](#input\_queue\_message\_retention\_seconds) | Message retention period (seconds) | `number` | `345600` | no |
| <a name="input_queue_name"></a> [queue\_name](#input\_queue\_name) | Queue name | `string` | `""` | no |
| <a name="input_queue_receive_wait_time_seconds"></a> [queue\_receive\_wait\_time\_seconds](#input\_queue\_receive\_wait\_time\_seconds) | Receive wait time (seconds) | `number` | `0` | no |
| <a name="input_r53_name"></a> [r53\_name](#input\_r53\_name) | The name for the route53 entry | `string` | `""` | no |
| <a name="input_rds_security_group"></a> [rds\_security\_group](#input\_rds\_security\_group) | The name of the RDS security group | `string` | n/a | yes |
| <a name="input_s3_name"></a> [s3\_name](#input\_s3\_name) | The name of the S3 bucket for storage | `string` | `""` | no |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |
| <a name="input_task_definition_cpu"></a> [task\_definition\_cpu](#input\_task\_definition\_cpu) | CPU units to allocate to the tasks | `string` | `"256"` | no |
| <a name="input_task_definition_memory"></a> [task\_definition\_memory](#input\_task\_definition\_memory) | RAM to allocate to the tasks | `string` | `"512"` | no |
| <a name="input_tasks_file"></a> [tasks\_file](#input\_tasks\_file) | Task template file to apply to the task definition | `string` | `"task-defn.json.tpl"` | no |
| <a name="input_tasks_folder"></a> [tasks\_folder](#input\_tasks\_folder) | Folder containing tasks templates to apply to the task definition | `string` | `"files"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The VPC CIDR range to extract | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC id to extract | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_fqdn_lb"></a> [fqdn\_lb](#output\_fqdn\_lb) | The FQDN of the R53 record fronting the LB for the PHP ASG |
| <a name="output_fqdn_lb_actual"></a> [fqdn\_lb\_actual](#output\_fqdn\_lb\_actual) | The LB endpoint for the PHP ASG |
<!-- END_TF_DOCS -->
