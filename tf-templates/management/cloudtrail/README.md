# template: management/cloudtrail

Provisions an AWS CloudTrail trail with a dedicated S3 bucket and bucket policy for storing audit logs.

## Resources Provisioned

- **CloudTrail trail** — Multi-region trail recording management and data events; configurable for hub (organisation-level) or spoke (single-account) mode
- **S3 bucket** — Dedicated bucket for CloudTrail log delivery with configurable lifecycle rules for log retention and archival
- **S3 bucket policy** — Allows CloudTrail to check bucket ACL and deliver logs; denies all non-HTTPS access

## Notes

- In the `abd-global` management account this trail is the centralised hub, configured to receive logs from all accounts in the organisation.
- Each workload account (`abd-wordpress`, etc.) has its own spoke trail that delivers logs to that account's CloudTrail bucket.
- Bucket policy is rendered from a template file to include the correct account IDs and trail ARN.

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
| <a name="module_cloudtrail-s3"></a> [cloudtrail-s3](#module\_cloudtrail-s3) | ../../../../abd-cloud-modules/storage/aws-s3 | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudtrail.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_acct_target"></a> [acct\_target](#input\_acct\_target) | Target AWS account to build infrastructure into | `string` | n/a | yes |
| <a name="input_acct_target_role"></a> [acct\_target\_role](#input\_acct\_target\_role) | Role in target account to assume when building infrastructure | `string` | `"terraform"` | no |
| <a name="input_cloudtrail_hub"></a> [cloudtrail\_hub](#input\_cloudtrail\_hub) | Is this the CloudTrail central hub | `bool` | `false` | no |
| <a name="input_cloudtrail_name"></a> [cloudtrail\_name](#input\_cloudtrail\_name) | The name of the CloudTrail configuration | `string` | n/a | yes |
| <a name="input_common_tag_component"></a> [common\_tag\_component](#input\_common\_tag\_component) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_environment"></a> [common\_tag\_environment](#input\_common\_tag\_environment) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_owner"></a> [common\_tag\_owner](#input\_common\_tag\_owner) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_project"></a> [common\_tag\_project](#input\_common\_tag\_project) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_subsystem"></a> [common\_tag\_subsystem](#input\_common\_tag\_subsystem) | n/a | `string` | n/a | yes |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_s3_lifecycle_rule"></a> [s3\_lifecycle\_rule](#input\_s3\_lifecycle\_rule) | A list of lifecycle rule objects to apply to the bucket | `list(any)` | `[]` | no |
| <a name="input_s3_name"></a> [s3\_name](#input\_s3\_name) | The name of the S3 bucket to hold the cloud-trail logs | `string` | n/a | yes |
| <a name="input_s3_tags"></a> [s3\_tags](#input\_s3\_tags) | Additional tags for the S3 bucket | `map(string)` | `{}` | no |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
