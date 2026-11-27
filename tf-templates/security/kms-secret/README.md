# template: security/kms-secret

A Secrets Manager secret with its own KMS key and a single access role, for a secret whose value is written outside Terraform (first use: the Tulox Kiosk Android Play upload key).

## Resources Provisioned

- **KMS key and alias.** Key rotation is on. The account root administers the key but gets no cryptographic actions. Only the access role may use the key, and only through Secrets Manager (`kms:ViaService` and `kms:CallerAccount`).
- **Secret** encrypted with that key, with a recovery window (30 days by default). It has **no value and no rotation**: the reason rotation does not apply is recorded as the `RotationExempt` tag.
- **Access role**, assumable by the listed principals (MFA required by default), with an inline policy limited to the one secret ARN and the one key ARN, HTTPS only:
  - Read: `secretsmanager:GetSecretValue`, `secretsmanager:DescribeSecret`, `kms:Decrypt`, `kms:DescribeKey`.
  - Initial write, while `allow_write = true`: `secretsmanager:PutSecretValue`, `kms:GenerateDataKey`. This is a separate statement, and the key policy grants `GenerateDataKey` only while it is on.

## Notes

- The value never passes through Terraform, so it is not in state. Write it once with the access role, then set `allow_write = false` and apply again to drop the write permissions.
- Other administrators in the account cannot decrypt the secret without first changing the key policy. They keep `kms:Put*` so the key cannot be orphaned, and any such change shows in CloudTrail.

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
| [aws_iam_role.access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kms_alias.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_iam_policy_document.access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.access_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_access_role_max_session_duration"></a> [access\_role\_max\_session\_duration](#input\_access\_role\_max\_session\_duration) | Maximum session duration of the access role, in seconds | `number` | `3600` | no |
| <a name="input_access_role_name"></a> [access\_role\_name](#input\_access\_role\_name) | Name of the IAM role that reads (and, while allow\_write is true, writes) the secret | `string` | n/a | yes |
| <a name="input_access_role_require_mfa"></a> [access\_role\_require\_mfa](#input\_access\_role\_require\_mfa) | Require MFA (aws:MultiFactorAuthPresent) to assume the access role | `bool` | `true` | no |
| <a name="input_access_role_trusted_principals"></a> [access\_role\_trusted\_principals](#input\_access\_role\_trusted\_principals) | IAM principal ARNs allowed to assume the access role | `list(string)` | n/a | yes |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_acct_target"></a> [acct\_target](#input\_acct\_target) | Target AWS account to build infrastructure into | `string` | n/a | yes |
| <a name="input_acct_target_role"></a> [acct\_target\_role](#input\_acct\_target\_role) | Role in target account to assume when building infrastructure | `string` | `"terraform"` | no |
| <a name="input_allow_write"></a> [allow\_write](#input\_allow\_write) | Grant the access role secretsmanager:PutSecretValue and kms:GenerateDataKey. Needed only to write the value; set false and apply again once it is written | `bool` | `true` | no |
| <a name="input_common_tag_component"></a> [common\_tag\_component](#input\_common\_tag\_component) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_environment"></a> [common\_tag\_environment](#input\_common\_tag\_environment) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_owner"></a> [common\_tag\_owner](#input\_common\_tag\_owner) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_project"></a> [common\_tag\_project](#input\_common\_tag\_project) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_subsystem"></a> [common\_tag\_subsystem](#input\_common\_tag\_subsystem) | n/a | `string` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Tags added to every resource on top of the common tags | `map(string)` | `{}` | no |
| <a name="input_kms_alias"></a> [kms\_alias](#input\_kms\_alias) | Alias for the dedicated KMS key, including the alias/ prefix (e.g. alias/tulox-kiosk-signing) | `string` | n/a | yes |
| <a name="input_kms_description"></a> [kms\_description](#input\_kms\_description) | Description of the dedicated KMS key | `string` | n/a | yes |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_recovery_window_in_days"></a> [recovery\_window\_in\_days](#input\_recovery\_window\_in\_days) | Days Secrets Manager keeps the secret recoverable after deletion (7 to 30) | `number` | `30` | no |
| <a name="input_rotation_exemption_reason"></a> [rotation\_exemption\_reason](#input\_rotation\_exemption\_reason) | Why automatic rotation does not apply to this secret. Recorded on the secret as the RotationExempt tag (tag value characters only: letters, numbers, spaces and \_ . : / = + - @) | `string` | n/a | yes |
| <a name="input_secret_description"></a> [secret\_description](#input\_secret\_description) | Description of the Secrets Manager secret | `string` | n/a | yes |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | Name of the Secrets Manager secret (e.g. tulox/kiosk/android-upload-key) | `string` | n/a | yes |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_access_role_arn"></a> [access\_role\_arn](#output\_access\_role\_arn) | ARN of the role the secret access policy is attached to. The role\_arn of the AWS CLI profile used to read the secret |
| <a name="output_kms_alias"></a> [kms\_alias](#output\_kms\_alias) | Alias of the KMS key |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the KMS key that encrypts the secret |
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | ARN of the Secrets Manager secret |
| <a name="output_write_enabled"></a> [write\_enabled](#output\_write\_enabled) | Whether the access role can still write the secret (allow\_write) |
<!-- END_TF_DOCS -->
