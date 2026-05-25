# template: storage/object

Provisions an S3 bucket via the `storage/aws-s3` module with configurable policy, lifecycle rules, versioning, logging, and transfer acceleration.

## Resources Provisioned

- **S3 bucket** — With KMS server-side encryption always enabled
- **Bucket policy** — Rendered from a template file in `var.policy_folder/var.policy_file`, receiving `s3_name` and `account_id` as template variables; falls back to `var.s3_policy` if set directly
- **Optional features** — Versioning, access logging, lifecycle rules, and transfer acceleration, each enabled by the corresponding variable

## Notes

- The bucket policy template mechanism allows complex policies (cross-account access, CloudTrail delivery restrictions, etc.) to be managed as separate JSON template files rather than inline HCL.
- When `s3_logging` is set, the target logging bucket must already exist and have the `log-delivery-write` ACL or equivalent bucket policy.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_abd-s3"></a> [abd-s3](#module\_abd-s3) | ../../../../abd-cloud-modules/storage/aws-s3 | n/a |

## Resources

No resources.

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
| <a name="input_files_folder"></a> [files\_folder](#input\_files\_folder) | Folder containing sample files to load to the bucket | `string` | `""` | no |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_policy_file"></a> [policy\_file](#input\_policy\_file) | Policy template file to apply to the bucket | `string` | `"blank.tpl.json"` | no |
| <a name="input_policy_folder"></a> [policy\_folder](#input\_policy\_folder) | Folder containing policy templates to apply to the bucket | `string` | `"./files"` | no |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_s3_acceleration_status"></a> [s3\_acceleration\_status](#input\_s3\_acceleration\_status) | Transfer acceleration status. Set to 'Enabled' to enable, or leave empty to leave unconfigured. | `string` | `""` | no |
| <a name="input_s3_acl"></a> [s3\_acl](#input\_s3\_acl) | The canned ACL to apply | `string` | `"private"` | no |
| <a name="input_s3_enable_mfa_delete"></a> [s3\_enable\_mfa\_delete](#input\_s3\_enable\_mfa\_delete) | Require an MFA device to delete objects | `bool` | `false` | no |
| <a name="input_s3_enable_versioning"></a> [s3\_enable\_versioning](#input\_s3\_enable\_versioning) | Enable object versioning | `bool` | `false` | no |
| <a name="input_s3_files"></a> [s3\_files](#input\_s3\_files) | List of sample files to load to the bucket | `list(string)` | `[]` | no |
| <a name="input_s3_files_tags"></a> [s3\_files\_tags](#input\_s3\_files\_tags) | Additional tags for the sample S3 bucket objects | `map(string)` | `{}` | no |
| <a name="input_s3_force_destroy"></a> [s3\_force\_destroy](#input\_s3\_force\_destroy) | Forcibly destroy all objects if removing the bucket - be careful! | `bool` | `false` | no |
| <a name="input_s3_lifecycle_rule"></a> [s3\_lifecycle\_rule](#input\_s3\_lifecycle\_rule) | A list of lifecycle rule objects to apply to the bucket | `list(any)` | `[]` | no |
| <a name="input_s3_logging"></a> [s3\_logging](#input\_s3\_logging) | Access logging configuration. Set to null to disable. | <pre>object({<br/>    target_bucket = string<br/>    target_prefix = string<br/>  })</pre> | `null` | no |
| <a name="input_s3_name"></a> [s3\_name](#input\_s3\_name) | The name of the S3 bucket | `any` | n/a | yes |
| <a name="input_s3_policy"></a> [s3\_policy](#input\_s3\_policy) | An S3 policy to apply to the bucket | `string` | `""` | no |
| <a name="input_s3_tags"></a> [s3\_tags](#input\_s3\_tags) | Additional tags for the S3 bucket | `map(string)` | `{}` | no |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_s3_arn"></a> [s3\_arn](#output\_s3\_arn) | The ARN of the S3 bucket |
| <a name="output_s3_bucket_domain_name"></a> [s3\_bucket\_domain\_name](#output\_s3\_bucket\_domain\_name) | The domain name of the S3 bucket |
| <a name="output_s3_bucket_regional_domain_name"></a> [s3\_bucket\_regional\_domain\_name](#output\_s3\_bucket\_regional\_domain\_name) | The regional domain name of the S3 bucket |
| <a name="output_s3_hosted_zone_id"></a> [s3\_hosted\_zone\_id](#output\_s3\_hosted\_zone\_id) | The R53 hosted zone id of the S3 bucket |
| <a name="output_s3_id"></a> [s3\_id](#output\_s3\_id) | The ID of the S3 bucket |
<!-- END_TF_DOCS -->
