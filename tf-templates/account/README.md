# template: account

Provisions account-level resources that are shared across all workloads in an AWS account. Run once per account during initial bootstrap, and re-applied when account-level configuration changes.

## Resources Provisioned

- **IAM roles** — RDS enhanced monitoring role, cross-account administrator access role, and (in the management account only) a GitHub Actions OIDC provider and IAM role for CI/CD
- **Route53** — Public hosted zone with a reusable delegation set; optional sub-domain delegation from an apex domain in another account; MX records for email routing
- **ECR** — Optional Docker repository with configurable lifecycle policy
- **CloudWatch** — Log groups for infrastructure, web, and application tiers
- **New Relic** — Optional monitoring integration role

## Bootstrap Order

This template must be applied before any other template in the account, as other templates depend on resources created here (IAM roles, DNS zones, log groups). In the management account (`abd-global`), apply this template first to create the GitHub Actions OIDC role used by all subsequent automated runs.

## Notes

- The GitHub Actions OIDC role is only created when `github_org` is non-empty. Set it in the management account config only; leave it empty in all other accounts.
- DNS delegation from an apex domain in another account requires that account's zone to already exist and be accessible via the cross-account `terraform` role.

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
| <a name="provider_aws.apex"></a> [aws.apex](#provider\_aws.apex) | 6.47.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cloudwatch_groups"></a> [cloudwatch\_groups](#module\_cloudwatch\_groups) | ../../../abd-cloud-modules/monitoring/cloudwatch/group | n/a |
| <a name="module_docker_repository"></a> [docker\_repository](#module\_docker\_repository) | ../../../abd-cloud-modules/compute/docker-repository | n/a |
| <a name="module_newrelic_role"></a> [newrelic\_role](#module\_newrelic\_role) | ../../../abd-cloud-modules/security/iam-role | n/a |
| <a name="module_r53_delegate"></a> [r53\_delegate](#module\_r53\_delegate) | ../../../abd-cloud-modules/network/dns/delegation-set | n/a |
| <a name="module_r53_mx"></a> [r53\_mx](#module\_r53\_mx) | ../../../abd-cloud-modules/network/dns/record | n/a |
| <a name="module_r53_public"></a> [r53\_public](#module\_r53\_public) | ../../../abd-cloud-modules/network/dns/public-zone | n/a |
| <a name="module_rds_monitoring_role"></a> [rds\_monitoring\_role](#module\_rds\_monitoring\_role) | ../../../abd-cloud-modules/security/iam-role | n/a |
| <a name="module_remote_admins"></a> [remote\_admins](#module\_remote\_admins) | ../../../abd-cloud-modules/security/iam-role | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_account_password_policy.strict](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_account_password_policy) | resource |
| [aws_iam_openid_connect_provider.github](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.github_actions_terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.github_actions_terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_service_linked_role.es](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_route53_record.apex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_iam_policy_document.newrelic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.rds_enhanced](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.remote_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.repository_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.apex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_acct_apex"></a> [acct\_apex](#input\_acct\_apex) | Account where Apex domain can be found | `string` | n/a | yes |
| <a name="input_acct_auth"></a> [acct\_auth](#input\_acct\_auth) | Authentication account number | `string` | n/a | yes |
| <a name="input_acct_target"></a> [acct\_target](#input\_acct\_target) | Target AWS account to build infrastructure into | `string` | n/a | yes |
| <a name="input_acct_target_role"></a> [acct\_target\_role](#input\_acct\_target\_role) | Role in target account to assume when building infrastructure | `string` | `"terraform"` | no |
| <a name="input_allow_users_to_change_password"></a> [allow\_users\_to\_change\_password](#input\_allow\_users\_to\_change\_password) | n/a | `bool` | `true` | no |
| <a name="input_cloudwatch_loggroup_names"></a> [cloudwatch\_loggroup\_names](#input\_cloudwatch\_loggroup\_names) | Log group names for cloudwatch | `list(string)` | <pre>[<br/>  "infra",<br/>  "web",<br/>  "app"<br/>]</pre> | no |
| <a name="input_cloudwatch_tags"></a> [cloudwatch\_tags](#input\_cloudwatch\_tags) | Additional tags for CloudWatch | `map(string)` | <pre>{<br/>  "Component": "cloudwatch"<br/>}</pre> | no |
| <a name="input_common_tag_component"></a> [common\_tag\_component](#input\_common\_tag\_component) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_environment"></a> [common\_tag\_environment](#input\_common\_tag\_environment) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_owner"></a> [common\_tag\_owner](#input\_common\_tag\_owner) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_project"></a> [common\_tag\_project](#input\_common\_tag\_project) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_subsystem"></a> [common\_tag\_subsystem](#input\_common\_tag\_subsystem) | n/a | `string` | n/a | yes |
| <a name="input_delegate_set_name"></a> [delegate\_set\_name](#input\_delegate\_set\_name) | A reference name for the delegate set | `string` | `""` | no |
| <a name="input_delegation_enabled"></a> [delegation\_enabled](#input\_delegation\_enabled) | Do we need this sub-domain delegated from our apex domain | `bool` | `false` | no |
| <a name="input_docker_repository_lifecycle_policy"></a> [docker\_repository\_lifecycle\_policy](#input\_docker\_repository\_lifecycle\_policy) | Lifecycle policies for ECR component | `string` | `""` | no |
| <a name="input_docker_repository_name"></a> [docker\_repository\_name](#input\_docker\_repository\_name) | Name of ECR repository | `string` | `"docker-repo"` | no |
| <a name="input_docker_repository_policy_file"></a> [docker\_repository\_policy\_file](#input\_docker\_repository\_policy\_file) | Policy template file to apply to the bucket | `string` | `"docker-repo-14-day-expire.tpl.json"` | no |
| <a name="input_docker_repository_policy_folder"></a> [docker\_repository\_policy\_folder](#input\_docker\_repository\_policy\_folder) | Folder containing policy templates to apply to the bucket | `string` | `"./files"` | no |
| <a name="input_docker_repository_required"></a> [docker\_repository\_required](#input\_docker\_repository\_required) | Defines whether we need to build a Docker repository in this account | `bool` | `false` | no |
| <a name="input_github_actions_role_name"></a> [github\_actions\_role\_name](#input\_github\_actions\_role\_name) | Name of the IAM role assumed by GitHub Actions via OIDC | `string` | `"github-actions-terraform"` | no |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | GitHub organisation name — set to enable OIDC role creation (management account only) | `string` | `""` | no |
| <a name="input_hard_expiry"></a> [hard\_expiry](#input\_hard\_expiry) | n/a | `bool` | `true` | no |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_minimum_password_length"></a> [minimum\_password\_length](#input\_minimum\_password\_length) | n/a | `number` | `10` | no |
| <a name="input_mx_records"></a> [mx\_records](#input\_mx\_records) | Records to use as MX records for this zone | `list(string)` | `[]` | no |
| <a name="input_newrelic_required"></a> [newrelic\_required](#input\_newrelic\_required) | Do we need to have NewRelic monitor the infrastructure for this account | `bool` | `false` | no |
| <a name="input_password_reuse_prevention"></a> [password\_reuse\_prevention](#input\_password\_reuse\_prevention) | n/a | `number` | `5` | no |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_r53_tags"></a> [r53\_tags](#input\_r53\_tags) | Additional tags for the Route53 Entries | `map(string)` | <pre>{<br/>  "Component": "account"<br/>}</pre> | no |
| <a name="input_remote_access_description"></a> [remote\_access\_description](#input\_remote\_access\_description) | The IAM policy describing cross account role assumption | `string` | `"Role used by automation"` | no |
| <a name="input_remote_access_name"></a> [remote\_access\_name](#input\_remote\_access\_name) | The IAM policy describing cross account role assumption | `string` | `"automation"` | no |
| <a name="input_remote_automation_hub"></a> [remote\_automation\_hub](#input\_remote\_automation\_hub) | Is this account the remote automation hub for automation | `bool` | `false` | no |
| <a name="input_require_lowercase_characters"></a> [require\_lowercase\_characters](#input\_require\_lowercase\_characters) | n/a | `bool` | `true` | no |
| <a name="input_require_numbers"></a> [require\_numbers](#input\_require\_numbers) | n/a | `bool` | `true` | no |
| <a name="input_require_symbols"></a> [require\_symbols](#input\_require\_symbols) | n/a | `bool` | `true` | no |
| <a name="input_require_uppercase_characters"></a> [require\_uppercase\_characters](#input\_require\_uppercase\_characters) | n/a | `bool` | `true` | no |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |
| <a name="input_use_existing_zones"></a> [use\_existing\_zones](#input\_use\_existing\_zones) | Re-use existing public and private zones | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_delegate_set_id"></a> [delegate\_set\_id](#output\_delegate\_set\_id) | The ID of the delegate set |
| <a name="output_delegate_set_name_servers"></a> [delegate\_set\_name\_servers](#output\_delegate\_set\_name\_servers) | The Name Servers of the delegate set |
| <a name="output_docker_registry_id"></a> [docker\_registry\_id](#output\_docker\_registry\_id) | n/a |
| <a name="output_docker_repository_arn"></a> [docker\_repository\_arn](#output\_docker\_repository\_arn) | n/a |
| <a name="output_docker_repository_name"></a> [docker\_repository\_name](#output\_docker\_repository\_name) | n/a |
| <a name="output_docker_repository_url"></a> [docker\_repository\_url](#output\_docker\_repository\_url) | n/a |
| <a name="output_public_zone_id"></a> [public\_zone\_id](#output\_public\_zone\_id) | The ID of the public zone |
| <a name="output_public_zone_name"></a> [public\_zone\_name](#output\_public\_zone\_name) | Route53 Public |
| <a name="output_public_zone_name_servers"></a> [public\_zone\_name\_servers](#output\_public\_zone\_name\_servers) | The Name Servers of the public zone |
<!-- END_TF_DOCS -->
