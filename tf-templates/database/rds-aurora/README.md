# template: database/rds-aurora

Provisions an Aurora RDS cluster with configurable engine (MySQL or PostgreSQL), cluster parameter group, instance parameter group, DB subnet group, and security groups.

## Resources Provisioned

- **Aurora cluster** — Engine version, master credentials, KMS encryption, backup retention, maintenance window, deletion protection
- **Aurora instances** — One or more instances (typically one writer, optional readers) in the cluster; instance class configurable
- **Parameter groups** — Cluster parameter group (character set, collation, timezone) and instance parameter group (query cache, slow query log, connection limits)
- **DB subnet group** — Multi-AZ subnet placement
- **Security groups** — Database tier security group with ingress rules from the application security group

## Notes

- Snapshot restoration is supported via `snapshot_identifier`. If set, the master password input is ignored (the password from the snapshot is used).
- IAM database authentication can be enabled for passwordless connections from EC2 instances with the appropriate IAM policy.
- The cluster and instance engine version should be kept in sync — mismatches between `engine_version` and the `db_family` in the parameter groups will cause plan errors.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_r53-aurora-ro"></a> [r53-aurora-ro](#module\_r53-aurora-ro) | ../../../../abd-cloud-modules/network/dns/record | n/a |
| <a name="module_r53-aurora-rw"></a> [r53-aurora-rw](#module\_r53-aurora-rw) | ../../../../abd-cloud-modules/network/dns/record | n/a |
| <a name="module_sg-aurora"></a> [sg-aurora](#module\_sg-aurora) | ../../../../abd-cloud-modules/security/security-group | n/a |
| <a name="module_sg-aurora-ingress-mysql"></a> [sg-aurora-ingress-mysql](#module\_sg-aurora-ingress-mysql) | ../../../../abd-cloud-modules/security/security-group-rule-cidr | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_rds_cluster.provisioned](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster.serverless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.provisioned](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_db_cluster_snapshot.cluster_snapshot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_cluster_snapshot) | data source |
| [aws_iam_role.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_route53_zone.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_acct_target"></a> [acct\_target](#input\_acct\_target) | Target AWS account to build infrastructure into | `string` | n/a | yes |
| <a name="input_acct_target_role"></a> [acct\_target\_role](#input\_acct\_target\_role) | Role in target account to assume when building infrastructure | `string` | `"terraform"` | no |
| <a name="input_admin_name"></a> [admin\_name](#input\_admin\_name) | The name of the admin user account | `string` | `"admin"` | no |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | The password of the admin user account | `string` | n/a | yes |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Create a final snapshot on termination | `bool` | `false` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | Availability zones to launch instances into | `list(string)` | `[]` | no |
| <a name="input_backtrack_window"></a> [backtrack\_window](#input\_backtrack\_window) | The backtrack window in seconds | `string` | `"0"` | no |
| <a name="input_backup_retention"></a> [backup\_retention](#input\_backup\_retention) | How many days of automated backups to retain | `string` | `"1"` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | When to run automated snapshots | `string` | `"02:00-02:30"` | no |
| <a name="input_build_from_latest_snapshot"></a> [build\_from\_latest\_snapshot](#input\_build\_from\_latest\_snapshot) | Create the cluster from the latest snapshot | `bool` | `true` | no |
| <a name="input_cloudwatch_logging"></a> [cloudwatch\_logging](#input\_cloudwatch\_logging) | List of cloudwatch logging options | `list(string)` | <pre>[<br/>  "audit",<br/>  "error",<br/>  "slowquery"<br/>]</pre> | no |
| <a name="input_common_tag_component"></a> [common\_tag\_component](#input\_common\_tag\_component) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_environment"></a> [common\_tag\_environment](#input\_common\_tag\_environment) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_owner"></a> [common\_tag\_owner](#input\_common\_tag\_owner) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_project"></a> [common\_tag\_project](#input\_common\_tag\_project) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_subsystem"></a> [common\_tag\_subsystem](#input\_common\_tag\_subsystem) | n/a | `string` | n/a | yes |
| <a name="input_engine"></a> [engine](#input\_engine) | The Aurora engine | `string` | `"aurora-mysql"` | no |
| <a name="input_engine_mode"></a> [engine\_mode](#input\_engine\_mode) | The Aurora engine mode (provisioned or serverless) | `string` | `"serverless"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The Aurora engine version | `string` | `"5.7.12"` | no |
| <a name="input_final_snapshot_identifier"></a> [final\_snapshot\_identifier](#input\_final\_snapshot\_identifier) | Name of final snapshot identifier to create if required | `string` | `""` | no |
| <a name="input_iam_authentication_enabled"></a> [iam\_authentication\_enabled](#input\_iam\_authentication\_enabled) | Enable IAM authentication for applications | `bool` | `false` | no |
| <a name="input_iam_roles"></a> [iam\_roles](#input\_iam\_roles) | List of IAM roles to associate with the cluster | `list(string)` | `[]` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | The instance class for the instances | `string` | `"db.t2.small"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key id to use when encrypting storage | `string` | `""` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | When to run default maintenance tasks | `string` | `"sun:03:00-sun:03:30"` | no |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_monitoring_interval"></a> [monitoring\_interval](#input\_monitoring\_interval) | The enhanced monitoring metric collection interval | `string` | `"60"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the Aurora Cluster | `string` | n/a | yes |
| <a name="input_param_group_name"></a> [param\_group\_name](#input\_param\_group\_name) | The cluster parameter group name | `string` | `"rds"` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Enable performance insight data collection | `bool` | `false` | no |
| <a name="input_performance_insights_kms_key_id"></a> [performance\_insights\_kms\_key\_id](#input\_performance\_insights\_kms\_key\_id) | KMS key to encrypt performance insight data | `string` | `""` | no |
| <a name="input_port"></a> [port](#input\_port) | Connection port | `string` | `"3306"` | no |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_r53_name"></a> [r53\_name](#input\_r53\_name) | The name for the route53 entry | `string` | `""` | no |
| <a name="input_rds_tags"></a> [rds\_tags](#input\_rds\_tags) | A map of RDS tags to add to all resources | `map(string)` | <pre>{<br/>  "Component": "rds aurora"<br/>}</pre> | no |
| <a name="input_read_replica_count"></a> [read\_replica\_count](#input\_read\_replica\_count) | The number of read replica instances to create | `string` | `"0"` | no |
| <a name="input_scaling_configuration"></a> [scaling\_configuration](#input\_scaling\_configuration) | RDS Aurora Serverless scaling configuration | `map(string)` | <pre>{<br/>  "auto_pause": true,<br/>  "max_capacity": 2,<br/>  "min_capacity": 1,<br/>  "seconds_until_auto_pause": 300<br/>}</pre> | no |
| <a name="input_schema_name"></a> [schema\_name](#input\_schema\_name) | The name of the initial schema to create if required | `string` | `""` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | Security groups for instances | `list(string)` | `[]` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Do not create a final snapshot on termination | `bool` | `true` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | Name of snapshot to create cluster from | `string` | `""` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Encrypt the RDS storage at rest | `bool` | `true` | no |
| <a name="input_subnet_group_name"></a> [subnet\_group\_name](#input\_subnet\_group\_name) | The db subnet group name | `string` | `"rds"` | no |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The VPC CIDR range to extract | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC id to extract | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The ARN of the Aurora Cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | The endpoint of the Aurora Cluster |
| <a name="output_cluster_hosted_zone_id"></a> [cluster\_hosted\_zone\_id](#output\_cluster\_hosted\_zone\_id) | The hosted\_zone\_id of the Aurora Cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The id of the Aurora Cluster |
| <a name="output_cluster_reader_endpoint"></a> [cluster\_reader\_endpoint](#output\_cluster\_reader\_endpoint) | The reader\_endpoint of the Aurora Cluster |
| <a name="output_instance_arns"></a> [instance\_arns](#output\_instance\_arns) | The ARNs of the Aurora Instances |
| <a name="output_instance_endpoints"></a> [instance\_endpoints](#output\_instance\_endpoints) | The Endpoints of the Aurora Instances |
| <a name="output_instance_ids"></a> [instance\_ids](#output\_instance\_ids) | The IDs of the Aurora Instances |
| <a name="output_monitor_role"></a> [monitor\_role](#output\_monitor\_role) | n/a |
<!-- END_TF_DOCS -->
