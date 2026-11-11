# template: compute/container-registry

Provisions a set of ECR repositories for one account from a single params folder, with lifecycle policies, an optional pull-through cache for ECR Public, and an optional managed pull policy for ECS execution roles.

## Resources Provisioned

- **ECR repositories**: one per entry in `repositories` (for example `abd/base`), through `abd-cloud-modules/compute/docker-repository`. Mutable tags by default, basic scan on push, `AES256`.
- **Lifecycle policies**: expire untagged images after 7 days and keep the newest 30 dated images (`*-20*`). Throwaway repositories can instead expire every image after a number of days (`expire_all_after_days`).
- **Pull-through cache** (optional, `pull_through_cache_prefix`): ECR Public as the upstream, plus a repository creation template so cached repositories get a lifecycle policy.
- **Pull policy** (optional, `pull_policy_name`): a managed IAM policy covering every repository namespace and the cache, for ECS execution roles.

## Notes

- Push access for CI comes from `security/github-deploy` (`ecr_push_roles`), not from this template.
- The pull-through cache rule and creation template are registry-wide, but scoped to their own prefix.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.72.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_repository"></a> [repository](#module\_repository) | ../../../../abd-cloud-modules/compute/docker-repository | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ecr_pull_through_cache_rule.ecr_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_pull_through_cache_rule) | resource |
| [aws_ecr_repository_creation_template.pull_through_cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_creation_template) | resource |
| [aws_iam_policy.pull](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.pull](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

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
| <a name="input_pull_policy_name"></a> [pull\_policy\_name](#input\_pull\_policy\_name) | Name of a managed IAM policy allowing pulls from these repositories and the pull-through cache, for ECS execution roles (empty for none) | `string` | `""` | no |
| <a name="input_pull_through_cache_keep_images"></a> [pull\_through\_cache\_keep\_images](#input\_pull\_through\_cache\_keep\_images) | Images to keep per repository created by the pull-through cache | `number` | `10` | no |
| <a name="input_pull_through_cache_prefix"></a> [pull\_through\_cache\_prefix](#input\_pull\_through\_cache\_prefix) | Repository prefix for an ECR Public (public.ecr.aws) pull-through cache, e.g. ecr-public (empty for none) | `string` | `""` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | ECR repositories to create, keyed by repository name (e.g. abd/base). Lifecycle: expire untagged images after untagged\_expiry\_days and keep the newest keep\_dated\_images images with a tag matching dated\_tag\_pattern; or, for throwaway repositories, expire every image after expire\_all\_after\_days. | <pre>map(object({<br/>    image_tag_mutability  = optional(string, "MUTABLE")<br/>    scan_on_push          = optional(bool, true)<br/>    untagged_expiry_days  = optional(number, 7)<br/>    keep_dated_images     = optional(number, 30)<br/>    dated_tag_pattern     = optional(string, "*-20*")<br/>    expire_all_after_days = optional(number)<br/>  }))</pre> | n/a | yes |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_pull_policy_arn"></a> [pull\_policy\_arn](#output\_pull\_policy\_arn) | Managed IAM policy ARN to attach to ECS execution roles (null when disabled) |
| <a name="output_pull_through_cache_prefix"></a> [pull\_through\_cache\_prefix](#output\_pull\_through\_cache\_prefix) | Prefix for images pulled through the ECR Public cache, e.g. <registry\_host>/<prefix>/docker/library/valkey:8 (null when disabled) |
| <a name="output_registry_host"></a> [registry\_host](#output\_registry\_host) | ECR registry host, for ECR\_REGISTRY in consuming GitHub repositories |
| <a name="output_repository_arns"></a> [repository\_arns](#output\_repository\_arns) | Repository ARNs, keyed by repository name |
| <a name="output_repository_urls"></a> [repository\_urls](#output\_repository\_urls) | Repository URLs, keyed by repository name |
<!-- END_TF_DOCS -->