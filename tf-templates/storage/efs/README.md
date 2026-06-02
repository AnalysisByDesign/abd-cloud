# template: storage/efs

Provisions an EFS file system with mount targets in each private subnet, a Route53 DNS record for discovery, and security groups controlling NFS access.

## Resources Provisioned

- **EFS file system** — Performance mode, throughput mode, and optional KMS encryption; lifecycle policy to transition infrequently accessed files to EFS-IA storage class
- **Mount targets** — One per subnet (typically one per AZ), allowing instances in those subnets to mount the file system
- **Security groups** — EFS security group accepting NFS (port 2049) from the application tier security group
- **Route53 record** — CNAME in the private hosted zone pointing to the EFS file system's DNS name for stable, human-readable access

## Notes

- EFS is used as shared persistent storage for WordPress media uploads, allowing the WordPress application tier to scale horizontally without each instance maintaining its own media store.
- Mount target security groups must allow outbound NFS from the EC2/ECS security group and inbound NFS to the EFS security group.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.47.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_efs"></a> [efs](#module\_efs) | ../../../../abd-cloud-modules/storage/efs | n/a |
| <a name="module_efs-sg"></a> [efs-sg](#module\_efs-sg) | ../../../../abd-cloud-modules/security/security-group | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_acct_target"></a> [acct\_target](#input\_acct\_target) | Target AWS account to build infrastructure into | `string` | n/a | yes |
| <a name="input_acct_target_role"></a> [acct\_target\_role](#input\_acct\_target\_role) | Role in target account to assume when building infrastructure | `string` | `"terraform"` | no |
| <a name="input_common_tag_component"></a> [common\_tag\_component](#input\_common\_tag\_component) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_environment"></a> [common\_tag\_environment](#input\_common\_tag\_environment) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_owner"></a> [common\_tag\_owner](#input\_common\_tag\_owner) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_project"></a> [common\_tag\_project](#input\_common\_tag\_project) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_subsystem"></a> [common\_tag\_subsystem](#input\_common\_tag\_subsystem) | n/a | `string` | n/a | yes |
| <a name="input_efs_tags"></a> [efs\_tags](#input\_efs\_tags) | Additional tags for the EFS volume | `map(string)` | <pre>{<br/>  "Component": "storage"<br/>}</pre> | no |
| <a name="input_encrypted"></a> [encrypted](#input\_encrypted) | Create an encrypted data volume | `bool` | `true` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Create an encrypted data volume | `string` | `""` | no |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the EFS volume | `string` | n/a | yes |
| <a name="input_performance_mode"></a> [performance\_mode](#input\_performance\_mode) | The performance mode of the EFS filesystem | `string` | `"generalPurpose"` | no |
| <a name="input_private_db_subnets"></a> [private\_db\_subnets](#input\_private\_db\_subnets) | A list of subnet CIDR ranges to be used for this EFS | `list(string)` | n/a | yes |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The VPC CIDR range to extract | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC id to extract | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_efs_dns_name"></a> [efs\_dns\_name](#output\_efs\_dns\_name) | The DNS name of the EFS volume |
| <a name="output_efs_id"></a> [efs\_id](#output\_efs\_id) | The ID of the EFS volume |
| <a name="output_efs_kms_key_id"></a> [efs\_kms\_key\_id](#output\_efs\_kms\_key\_id) | The KMS key ID of the EFS volume |
<!-- END_TF_DOCS -->
