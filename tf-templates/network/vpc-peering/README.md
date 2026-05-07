# template: network/vpc-peering

Establishes a cross-account VPC peering connection between two VPCs, adds routes in both VPCs' route tables, and configures DNS resolution across the peering link.

## Resources Provisioned

- **VPC peering connection** — Requester side: peering request from one VPC to another (can be cross-account and/or cross-region)
- **Peering accepter** — Automatic acceptance on the accepter side using the target account's `terraform` role
- **Routes** — Entries added to the requester and accepter route tables pointing to the peering connection
- **DNS** — `allow_remote_vpc_dns_resolution` enabled on both sides so private hosted zone records resolve across the peering link

## Notes

- Both the requester and accepter AWS providers must be configured. The template uses a `provider "aws" { alias = "peer" }` block that assumes the peer account's `terraform` role.
- Route table updates require knowing the route table IDs from both VPCs — these are outputs from the `network/vpc` template.

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
| <a name="provider_aws.accepter"></a> [aws.accepter](#provider\_aws.accepter) | 5.100.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_route.accepter_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.accepter_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.requester_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.requester_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_vpc_peering_connection.requester](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection) | resource |
| [aws_vpc_peering_connection_accepter.accepter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_accepter) | resource |
| [aws_vpc_peering_connection_options.accepter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_options) | resource |
| [aws_vpc_peering_connection_options.requester](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_peering_connection_options) | resource |
| [aws_caller_identity.accepter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_vpc.accepter_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [terraform_remote_state.accepter](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.requester](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_accepter_region"></a> [accepter\_region](#input\_accepter\_region) | The region of the accepter VPC | `string` | `""` | no |
| <a name="input_accepter_target"></a> [accepter\_target](#input\_accepter\_target) | Accepter AWS account to receive peering request | `string` | n/a | yes |
| <a name="input_accepter_target_role"></a> [accepter\_target\_role](#input\_accepter\_target\_role) | Role in accepter account to use to approve peering request | `string` | `""` | no |
| <a name="input_accepter_vpc_cidr"></a> [accepter\_vpc\_cidr](#input\_accepter\_vpc\_cidr) | The VPC CIDR range to make the peering link to | `string` | `""` | no |
| <a name="input_accepter_vpc_id"></a> [accepter\_vpc\_id](#input\_accepter\_vpc\_id) | The VPC id range to make the peering link to | `string` | `""` | no |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_acct_target"></a> [acct\_target](#input\_acct\_target) | Target AWS account to build infrastructure into | `string` | n/a | yes |
| <a name="input_acct_target_role"></a> [acct\_target\_role](#input\_acct\_target\_role) | Role in target account to assume when building infrastructure | `string` | `"terraform"` | no |
| <a name="input_common_tag_component"></a> [common\_tag\_component](#input\_common\_tag\_component) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_environment"></a> [common\_tag\_environment](#input\_common\_tag\_environment) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_owner"></a> [common\_tag\_owner](#input\_common\_tag\_owner) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_project"></a> [common\_tag\_project](#input\_common\_tag\_project) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_subsystem"></a> [common\_tag\_subsystem](#input\_common\_tag\_subsystem) | n/a | `string` | n/a | yes |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_private_accepter_cidr_override"></a> [private\_accepter\_cidr\_override](#input\_private\_accepter\_cidr\_override) | Optional CIDR range to forward through peering to the accepter from private subnets | `string` | `""` | no |
| <a name="input_private_requester_cidr_override"></a> [private\_requester\_cidr\_override](#input\_private\_requester\_cidr\_override) | Optional CIDR range to forward through peering to the requester from private subnets | `string` | `""` | no |
| <a name="input_public_accepter_cidr_override"></a> [public\_accepter\_cidr\_override](#input\_public\_accepter\_cidr\_override) | Optional CIDR range to forward through peering to the accepter from public subnets | `string` | `""` | no |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_requester_cidr_override"></a> [public\_requester\_cidr\_override](#input\_public\_requester\_cidr\_override) | Optional CIDR range to forward through peering to the requester from public subnets | `string` | `""` | no |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The VPC CIDR range to extract | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC id to extract | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_accepter_connection_options_id"></a> [accepter\_connection\_options\_id](#output\_accepter\_connection\_options\_id) | The ID of the VPC Peering Connection Options |
| <a name="output_requester_connection_options_id"></a> [requester\_connection\_options\_id](#output\_requester\_connection\_options\_id) | The ID of the VPC Peering Connection Options |
<!-- END_TF_DOCS -->
