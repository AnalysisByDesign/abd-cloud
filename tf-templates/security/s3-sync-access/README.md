# template: security/s3-sync-access

Roles that push content into a single prefix of an S3 bucket, for machines outside AWS (first use: Tulox marketing images from the dev Mac mini into `abd-wordpress-tulox-media/marketing-images/`).

## Resources Provisioned

- **IAM role** per entry in `sync_roles`: `s3:ListBucket` limited to the prefix, `s3:GetObject` and `s3:PutObject` under it, `kms:Decrypt`/`kms:GenerateDataKey` on the bucket key when one is given, and an explicit deny on object deletes, lifecycle and versioning changes. One hour sessions by default.
- **IAM user** (optional, `user_name`) whose only permission is `sts:AssumeRole` on its role, and which is the role's only trusted principal.

## Notes

- Additive only. A push can add or overwrite objects but never remove one. On a bucket without versioning an overwrite replaces the object, so publishers should use content-hashed, immutable names.
- The user's access key is **not** created by Terraform, so the secret never reaches state. Create it by hand and put it straight onto the machine that uses it:

  ```bash
  aws-vault exec abd_wp -- aws iam create-access-key --user-name <user_name>
  ```

  The machine then uses a source profile holding that key and a profile with `role_arn` set to the sync role.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.74.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role.sync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.sync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_user.sync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy.sync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy) | resource |
| [aws_iam_policy_document.sync_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sync_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.sync_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

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
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_sync_roles"></a> [sync\_roles](#input\_sync\_roles) | Roles that push content into one S3 prefix, keyed by a short name. Each role may list the prefix and read and write objects under it, and nothing else: no delete or version action is granted, and object deletes and lifecycle changes on the bucket are explicitly denied. An optional IAM user can assume the role from outside AWS; its access key is created by hand, never by Terraform, so the secret stays out of state. | <pre>map(object({<br/>    role_name            = string                 # Name of the IAM role<br/>    bucket               = string                 # Bucket name (not ARN)<br/>    prefix               = string                 # Key prefix without slashes, e.g. marketing-images<br/>    kms_key_arn          = optional(string, "")   # Customer managed key that encrypts the bucket. Empty for SSE-S3<br/>    max_session_duration = optional(number, 3600) # Seconds<br/>    # IAM user whose only permission is sts:AssumeRole on this role, for a machine outside AWS.<br/>    # Empty creates no user, and the role then trusts nobody until a trust route is added.<br/>    user_name = optional(string, "")<br/>  }))</pre> | `{}` | no |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_sync_role_arns"></a> [sync\_role\_arns](#output\_sync\_role\_arns) | Sync role ARNs, keyed by name. The role\_arn in the pushing machine's AWS profile |
| <a name="output_sync_user_names"></a> [sync\_user\_names](#output\_sync\_user\_names) | IAM users that may assume each sync role, keyed by name. Create their access key by hand |
<!-- END_TF_DOCS -->
