# template: compute/ec2-asg

Provisions a complete EC2-based application tier: launch template, Auto Scaling Group, Application Load Balancer, SSL certificate, Route53 DNS record, SQS queue, security groups, and an IAM instance profile.

## Resources Provisioned

- **Launch template** — AMI, instance type, EBS volumes, IAM profile, user data script (rendered via `templatefile()`), and security group assignment
- **Auto Scaling Group** — Min/max/desired counts, VPC subnet placement, health check configuration, and target group attachment
- **ALB** — Internet-facing with HTTPS listener, HTTP redirect, and target group; optional WAFv2 association
- **SSL certificate** — ACM certificate validated via Route53 DNS records
- **Route53** — Alias record from the application domain to the ALB
- **SQS** — Application event queue with optional DLQ
- **Security groups** — ALB, application, and inter-tier rules
- **IAM** — Instance profile role with configurable policies for S3, SSM, and SQS access

## Notes

- The user data script is rendered from a template file at `var.user_data_script_folder/var.user_data_script`. The template receives `env` and `name` variables.
- The IAM policy document template at `var.ec2_policy_template_folder/var.ec2_policy_template` receives `s3_name` and `ssm_key_prefix` variables.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_alb-ec2-sgr"></a> [alb-ec2-sgr](#module\_alb-ec2-sgr) | ../../../../abd-cloud-modules/security/security-group-rule-link | n/a |
| <a name="module_alb-sg"></a> [alb-sg](#module\_alb-sg) | ../../../../abd-cloud-modules/security/security-group | n/a |
| <a name="module_alb-sgr-http-in"></a> [alb-sgr-http-in](#module\_alb-sgr-http-in) | ../../../../abd-cloud-modules/security/security-group-rule-cidr | n/a |
| <a name="module_alb-sgr-https-in"></a> [alb-sgr-https-in](#module\_alb-sgr-https-in) | ../../../../abd-cloud-modules/security/security-group-rule-cidr | n/a |
| <a name="module_autoscaling-group"></a> [autoscaling-group](#module\_autoscaling-group) | ../../../../abd-cloud-modules/compute/asg | n/a |
| <a name="module_dns_load_balancer"></a> [dns\_load\_balancer](#module\_dns\_load\_balancer) | ../../../../abd-cloud-modules/network/dns/alias-record | n/a |
| <a name="module_ec2-alb-sgr"></a> [ec2-alb-sgr](#module\_ec2-alb-sgr) | ../../../../abd-cloud-modules/security/security-group-rule-link | n/a |
| <a name="module_ec2-all-traffic-out"></a> [ec2-all-traffic-out](#module\_ec2-all-traffic-out) | ../../../../abd-cloud-modules/security/security-group-rule-cidr | n/a |
| <a name="module_ec2-efs-sgr"></a> [ec2-efs-sgr](#module\_ec2-efs-sgr) | ../../../../abd-cloud-modules/security/security-group-rule-link | n/a |
| <a name="module_ec2-rds-sgr"></a> [ec2-rds-sgr](#module\_ec2-rds-sgr) | ../../../../abd-cloud-modules/security/security-group-rule-link | n/a |
| <a name="module_ec2-sg"></a> [ec2-sg](#module\_ec2-sg) | ../../../../abd-cloud-modules/security/security-group | n/a |
| <a name="module_ec2_asg_policy"></a> [ec2\_asg\_policy](#module\_ec2\_asg\_policy) | ../../../../abd-cloud-modules/security/iam-policy | n/a |
| <a name="module_ec2_asg_role"></a> [ec2\_asg\_role](#module\_ec2\_asg\_role) | ../../../../abd-cloud-modules/security/iam-role | n/a |
| <a name="module_efs-ec2-sgr"></a> [efs-ec2-sgr](#module\_efs-ec2-sgr) | ../../../../abd-cloud-modules/security/security-group-rule-link | n/a |
| <a name="module_launch_template"></a> [launch\_template](#module\_launch\_template) | ../../../../abd-cloud-modules/compute/launch-template | n/a |
| <a name="module_load_balancer"></a> [load\_balancer](#module\_load\_balancer) | ../../../../abd-cloud-modules/compute/alb | n/a |
| <a name="module_queue"></a> [queue](#module\_queue) | ../../../../abd-cloud-modules/integrate/queue | n/a |
| <a name="module_queue-dead-letter"></a> [queue-dead-letter](#module\_queue-dead-letter) | ../../../../abd-cloud-modules/integrate/queue | n/a |
| <a name="module_rds-ec2-sgr"></a> [rds-ec2-sgr](#module\_rds-ec2-sgr) | ../../../../abd-cloud-modules/security/security-group-rule-link | n/a |
| <a name="module_ssh-key-pair"></a> [ssh-key-pair](#module\_ssh-key-pair) | ../../../../abd-cloud-modules/security/ssh-key | n/a |
| <a name="module_ssl_cert"></a> [ssl\_cert](#module\_ssl\_cert) | ../../../../abd-cloud-modules/security/ssl-certs | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_instance_profile.ec2-asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role_policy_attachment.attach_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.instance_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_security_group.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_subnet.asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
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
| <a name="input_asg_ami_image_glob"></a> [asg\_ami\_image\_glob](#input\_asg\_ami\_image\_glob) | The EC2 AMI image name to search for | `string` | n/a | yes |
| <a name="input_asg_ami_image_owner"></a> [asg\_ami\_image\_owner](#input\_asg\_ami\_image\_owner) | The EC2 AMI image owner | `string` | n/a | yes |
| <a name="input_asg_capacity_timeout"></a> [asg\_capacity\_timeout](#input\_asg\_capacity\_timeout) | Maximum | `string` | `"600s"` | no |
| <a name="input_asg_default_cooldown"></a> [asg\_default\_cooldown](#input\_asg\_default\_cooldown) | Cooldown period before allowing another autoscaling action | `string` | `"120"` | no |
| <a name="input_asg_delete_timeout"></a> [asg\_delete\_timeout](#input\_asg\_delete\_timeout) | Delete timeout setting | `string` | `"15m"` | no |
| <a name="input_asg_desired_capacity"></a> [asg\_desired\_capacity](#input\_asg\_desired\_capacity) | Desired size of the autoscaling group | `string` | `"0"` | no |
| <a name="input_asg_ec2_instance_type"></a> [asg\_ec2\_instance\_type](#input\_asg\_ec2\_instance\_type) | The EC2 instance type to build | `string` | `"t3.micro"` | no |
| <a name="input_asg_force_delete"></a> [asg\_force\_delete](#input\_asg\_force\_delete) | Force delete of autoscaling group if instances not terminating | `string` | `"false"` | no |
| <a name="input_asg_health_check_grace_period"></a> [asg\_health\_check\_grace\_period](#input\_asg\_health\_check\_grace\_period) | Maximum | `string` | `"240"` | no |
| <a name="input_asg_iam_profile_name"></a> [asg\_iam\_profile\_name](#input\_asg\_iam\_profile\_name) | IAM instance profile to use for EC2 instances | `string` | `""` | no |
| <a name="input_asg_max_size"></a> [asg\_max\_size](#input\_asg\_max\_size) | Maximum size of the autoscaling group | `string` | `"1"` | no |
| <a name="input_asg_min_size"></a> [asg\_min\_size](#input\_asg\_min\_size) | Minimum size of the autoscaling group | `string` | `"0"` | no |
| <a name="input_asg_ssh_key_name"></a> [asg\_ssh\_key\_name](#input\_asg\_ssh\_key\_name) | Name of SSH key to upload | `string` | n/a | yes |
| <a name="input_asg_ssh_public_key_file"></a> [asg\_ssh\_public\_key\_file](#input\_asg\_ssh\_public\_key\_file) | Physical file location of public key part to upload | `string` | n/a | yes |
| <a name="input_asg_termination_policies"></a> [asg\_termination\_policies](#input\_asg\_termination\_policies) | Termination policies to apply to instances | `list(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_common_tag_component"></a> [common\_tag\_component](#input\_common\_tag\_component) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_environment"></a> [common\_tag\_environment](#input\_common\_tag\_environment) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_owner"></a> [common\_tag\_owner](#input\_common\_tag\_owner) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_project"></a> [common\_tag\_project](#input\_common\_tag\_project) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_subsystem"></a> [common\_tag\_subsystem](#input\_common\_tag\_subsystem) | n/a | `string` | n/a | yes |
| <a name="input_ec2_policy_template"></a> [ec2\_policy\_template](#input\_ec2\_policy\_template) | IAM Policy template file | `string` | `"s3-access-policy.tpl.json"` | no |
| <a name="input_ec2_policy_template_folder"></a> [ec2\_policy\_template\_folder](#input\_ec2\_policy\_template\_folder) | Folder containing policy templates to apply to the instance roles | `string` | `"./files"` | no |
| <a name="input_efs_security_group"></a> [efs\_security\_group](#input\_efs\_security\_group) | The name of the EFS security group | `string` | `""` | no |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | The name prefix of the various resources | `string` | n/a | yes |
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
| <a name="input_user_data_script"></a> [user\_data\_script](#input\_user\_data\_script) | User data template file to apply to the instance | `string` | `"blank-user-data.tpl.sh"` | no |
| <a name="input_user_data_script_folder"></a> [user\_data\_script\_folder](#input\_user\_data\_script\_folder) | Folder containing user data templates to apply to the instances | `string` | `"./files"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The VPC CIDR range to extract | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC id to extract | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_fqdn_lb"></a> [fqdn\_lb](#output\_fqdn\_lb) | DNS entry for direct access to the Load Balancer |
| <a name="output_fqdn_lb_actual"></a> [fqdn\_lb\_actual](#output\_fqdn\_lb\_actual) | The LB endpoint for the PHP ASG |
<!-- END_TF_DOCS -->
