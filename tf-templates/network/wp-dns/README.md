# template: network/wp-dns

Provisions the complete DNS, SSL, and routing configuration for a single WordPress hosted site: Route53 hosted zone, ALB alias records (apex and www), MX records, and an ACM certificate.

## Resources Provisioned

- **Route53 public zone** — Hosted zone for the domain, created with the account-level delegation set for consistent name servers
- **ALB alias records** — Apex domain (`example.co.uk`) and `www` subdomain both alias to the Application Load Balancer DNS name
- **MX records** — Mail exchange records for the domain
- **ACM certificate** — SSL certificate covering the apex domain and `www` SAN, with DNS validation records created in the Route53 zone

## Notes

- This template is applied once per hosted domain. All eight WordPress domains in the platform each have their own params directory under `hosted-sites/`.
- The delegation set used must already exist (created by the `account` template). The name servers in the delegation set must be registered with the domain registrar before DNS will resolve.
- The ACM certificate waits for DNS validation to complete before marking the resource as created, so plan time is short but apply may take several minutes on first run.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.46.0 |
| <a name="provider_aws.apex"></a> [aws.apex](#provider\_aws.apex) | 6.46.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_dns_naked"></a> [dns\_naked](#module\_dns\_naked) | ../../../../abd-cloud-modules/network/dns/alias-record | n/a |
| <a name="module_dns_subdomain"></a> [dns\_subdomain](#module\_dns\_subdomain) | ../../../../abd-cloud-modules/network/dns/alias-record | n/a |
| <a name="module_dns_www"></a> [dns\_www](#module\_dns\_www) | ../../../../abd-cloud-modules/network/dns/record | n/a |
| <a name="module_r53_delegate"></a> [r53\_delegate](#module\_r53\_delegate) | ../../../../abd-cloud-modules/network/dns/delegation-set | n/a |
| <a name="module_r53_mx"></a> [r53\_mx](#module\_r53\_mx) | ../../../../abd-cloud-modules/network/dns/record | n/a |
| <a name="module_r53_public"></a> [r53\_public](#module\_r53\_public) | ../../../../abd-cloud-modules/network/dns/public-zone | n/a |
| <a name="module_ssl_cert"></a> [ssl\_cert](#module\_ssl\_cert) | ../../../../abd-cloud-modules/security/ssl-certs | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_lb_listener_certificate.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_route53_record.apex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_lb.wordpress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb) | data source |
| [aws_lb_listener.wordpress443](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb_listener) | data source |
| [aws_route53_zone.apex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_route53_zone.wordpress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_acct_apex"></a> [acct\_apex](#input\_acct\_apex) | Account where Apex domain can be found | `string` | n/a | yes |
| <a name="input_acct_target"></a> [acct\_target](#input\_acct\_target) | Target AWS account to build infrastructure into | `string` | n/a | yes |
| <a name="input_acct_target_role"></a> [acct\_target\_role](#input\_acct\_target\_role) | Role in target account to assume when building infrastructure | `string` | `"terraform"` | no |
| <a name="input_common_tag_component"></a> [common\_tag\_component](#input\_common\_tag\_component) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_environment"></a> [common\_tag\_environment](#input\_common\_tag\_environment) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_owner"></a> [common\_tag\_owner](#input\_common\_tag\_owner) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_project"></a> [common\_tag\_project](#input\_common\_tag\_project) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_subsystem"></a> [common\_tag\_subsystem](#input\_common\_tag\_subsystem) | n/a | `string` | n/a | yes |
| <a name="input_delegate_set_name"></a> [delegate\_set\_name](#input\_delegate\_set\_name) | A reference name for the delegate set | `string` | `""` | no |
| <a name="input_delegation_enabled"></a> [delegation\_enabled](#input\_delegation\_enabled) | Do we need this sub-domain delegated from our apex domain | `bool` | `false` | no |
| <a name="input_dns_extra"></a> [dns\_extra](#input\_dns\_extra) | Extra DNS records that might be required | `list(map(string))` | `[]` | no |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_mx_records"></a> [mx\_records](#input\_mx\_records) | Records to use as MX records for this zone | `list(string)` | `[]` | no |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_r53_tags"></a> [r53\_tags](#input\_r53\_tags) | Additional tags for the Route53 Entries | `map(string)` | <pre>{<br/>  "Component": "account"<br/>}</pre> | no |
| <a name="input_ssl_cert_enabled"></a> [ssl\_cert\_enabled](#input\_ssl\_cert\_enabled) | Does this site require an SSL cert. (Always false until NameServer change) | `bool` | `true` | no |
| <a name="input_subject_alternative_names"></a> [subject\_alternative\_names](#input\_subject\_alternative\_names) | Subject alternative names for the SSL cert if required | `list(string)` | `[]` | no |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |
| <a name="input_use_existing_zones"></a> [use\_existing\_zones](#input\_use\_existing\_zones) | Re-use existing public and private zones | `bool` | `false` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The VPC CIDR range to extract | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC id to extract | `string` | `""` | no |
| <a name="input_wp_apex_domain"></a> [wp\_apex\_domain](#input\_wp\_apex\_domain) | The public wordpress apex domain | `string` | n/a | yes |
| <a name="input_wp_lb_name"></a> [wp\_lb\_name](#input\_wp\_lb\_name) | The load balancer name for the main WP installation | `string` | n/a | yes |
| <a name="input_wp_sub_domain"></a> [wp\_sub\_domain](#input\_wp\_sub\_domain) | The public wordpress subdomain domain prefix | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_domain_validation_options"></a> [domain\_validation\_options](#output\_domain\_validation\_options) | n/a |
<!-- END_TF_DOCS -->
