# template: network/vpc

Provisions a complete VPC networking stack across three Availability Zones, including all subnets, routing, gateways, endpoints, and optional database and cache infrastructure groups.

## Resources Provisioned

- **VPC** — CIDR block, DNS hostnames and resolution enabled
- **Subnets** — Five subnet tiers per AZ: public (`/26`), private-web (`/25`), private-app (`/24`), cache (`/27`), database (`/27`)
- **Internet Gateway** — For public subnet outbound routing
- **NAT Gateways** — One per AZ in public subnets, routing private subnet egress (configurable: none, single, or per-AZ)
- **Route tables** — Public (via IGW), private (via NAT), and database (local only)
- **VPC Endpoints** — S3 gateway endpoint for private subnet access without NAT
- **Security groups** — Baseline security groups for each tier
- **DB subnet group** — Spanning the database subnets across all AZs
- **Cache subnet group** — Spanning the cache subnets across all AZs
- **RDS parameter groups** — Cluster (provisioned), cluster (serverless aurora5.6), and instance parameter groups
- **ElastiCache parameter group** — Redis cluster parameter group (created when `cache_cluster_param_group_name` is set)
- **DNS** — Public and private hosted zones with delegation set

## Notes

- This is the most complex template and creates resources that nearly all other templates depend on. Apply it before compute, database, storage, or application templates.
- NAT gateway count is controlled by `nat_gateway_count`: `0` for no outbound internet, `1` for cost-optimised single NAT, or `3` for production HA.
- VPC CIDR is divided using predictable `/26`–`/24` blocks. The subnet scheme assumes a `/20` or larger VPC CIDR to leave room for all tiers across three AZs.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.15.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.46.0 |
| <a name="provider_aws.apex"></a> [aws.apex](#provider\_aws.apex) | 6.46.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_cache-cluster-param-group"></a> [cache-cluster-param-group](#module\_cache-cluster-param-group) | ../../../../abd-cloud-modules/cache/cluster-param-group | n/a |
| <a name="module_cache-subnet-group"></a> [cache-subnet-group](#module\_cache-subnet-group) | ../../../../abd-cloud-modules/network/cache-subnet-group | n/a |
| <a name="module_db-cluster-param-group-provisioned"></a> [db-cluster-param-group-provisioned](#module\_db-cluster-param-group-provisioned) | ../../../../abd-cloud-modules/database/cluster-param-group | n/a |
| <a name="module_db-cluster-param-group-serverless"></a> [db-cluster-param-group-serverless](#module\_db-cluster-param-group-serverless) | ../../../../abd-cloud-modules/database/cluster-param-group | n/a |
| <a name="module_db-param-group"></a> [db-param-group](#module\_db-param-group) | ../../../../abd-cloud-modules/database/param-group | n/a |
| <a name="module_db-subnet-group"></a> [db-subnet-group](#module\_db-subnet-group) | ../../../../abd-cloud-modules/network/db-subnet-group | n/a |
| <a name="module_management-ssh-sg"></a> [management-ssh-sg](#module\_management-ssh-sg) | ../../../../abd-cloud-modules/security/security-group | n/a |
| <a name="module_management-ssh-sgr-in"></a> [management-ssh-sgr-in](#module\_management-ssh-sgr-in) | ../../../../abd-cloud-modules/security/security-group-rule-cidr | n/a |
| <a name="module_r53_delegate"></a> [r53\_delegate](#module\_r53\_delegate) | ../../../../abd-cloud-modules/network/dns/delegation-set | n/a |
| <a name="module_r53_private"></a> [r53\_private](#module\_r53\_private) | ../../../../abd-cloud-modules/network/dns/private-zone | n/a |
| <a name="module_r53_public"></a> [r53\_public](#module\_r53\_public) | ../../../../abd-cloud-modules/network/dns/public-zone | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_default_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table) | resource |
| [aws_default_security_group.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_dx_gateway_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dx_gateway_association) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route53_record.apex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone_association.secondary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone_association) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private-app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private-cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private-db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private-web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private-app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private-cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private-db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private-web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_dhcp_options.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options) | resource |
| [aws_vpc_dhcp_options_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options_association) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_route_table_association.s3_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_route_table_association) | resource |
| [aws_vpn_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway) | resource |
| [aws_vpn_gateway_route_propagation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway_route_propagation) | resource |
| [aws_dx_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/dx_gateway) | data source |
| [aws_route53_zone.apex](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_route53_zone.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_acct_apex"></a> [acct\_apex](#input\_acct\_apex) | Account where Apex domain can be found | `string` | n/a | yes |
| <a name="input_acct_target"></a> [acct\_target](#input\_acct\_target) | Target AWS account to build infrastructure into | `string` | n/a | yes |
| <a name="input_acct_target_role"></a> [acct\_target\_role](#input\_acct\_target\_role) | Role in target account to assume when building infrastructure | `string` | `"terraform"` | no |
| <a name="input_amazon_side_asn"></a> [amazon\_side\_asn](#input\_amazon\_side\_asn) | AWS ASN | `string` | `"64512"` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | A list of AZs to be used for this deployment | `list(string)` | <pre>[<br/>  "eu-west-1a",<br/>  "eu-west-1b",<br/>  "eu-west-1c"<br/>]</pre> | no |
| <a name="input_cache_cluster_param_group_name"></a> [cache\_cluster\_param\_group\_name](#input\_cache\_cluster\_param\_group\_name) | Name of Elasticache param group table | `string` | `"redis-cluster"` | no |
| <a name="input_cache_cluster_param_group_tags"></a> [cache\_cluster\_param\_group\_tags](#input\_cache\_cluster\_param\_group\_tags) | A map of tags to add to param group | `map(string)` | <pre>{<br/>  "Component": "Elasticache Redis"<br/>}</pre> | no |
| <a name="input_cache_subnet_group_name"></a> [cache\_subnet\_group\_name](#input\_cache\_subnet\_group\_name) | Name of Elasticache subnet group table | `string` | `"cache"` | no |
| <a name="input_cache_subnet_tags"></a> [cache\_subnet\_tags](#input\_cache\_subnet\_tags) | A map of subnet tags to add to subnet group | `map(string)` | <pre>{<br/>  "Component": "Cache cluster"<br/>}</pre> | no |
| <a name="input_common_tag_component"></a> [common\_tag\_component](#input\_common\_tag\_component) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_environment"></a> [common\_tag\_environment](#input\_common\_tag\_environment) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_owner"></a> [common\_tag\_owner](#input\_common\_tag\_owner) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_project"></a> [common\_tag\_project](#input\_common\_tag\_project) | n/a | `string` | n/a | yes |
| <a name="input_common_tag_subsystem"></a> [common\_tag\_subsystem](#input\_common\_tag\_subsystem) | n/a | `string` | n/a | yes |
| <a name="input_connect_to_mpls"></a> [connect\_to\_mpls](#input\_connect\_to\_mpls) | Connect the private route tables to the MPLS cloud via direct connect? | `bool` | `false` | no |
| <a name="input_db_param_group_name"></a> [db\_param\_group\_name](#input\_db\_param\_group\_name) | Name of DB param group table | `string` | `"rds"` | no |
| <a name="input_db_param_group_tags"></a> [db\_param\_group\_tags](#input\_db\_param\_group\_tags) | A map of tags to add to param group | `map(string)` | <pre>{<br/>  "Component": "rds"<br/>}</pre> | no |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | Name of DB subnet group table | `string` | `"rds"` | no |
| <a name="input_db_subnet_tags"></a> [db\_subnet\_tags](#input\_db\_subnet\_tags) | A map of subnet tags to add to subnet group | `map(string)` | <pre>{<br/>  "Component": "rds"<br/>}</pre> | no |
| <a name="input_delegate_set_name"></a> [delegate\_set\_name](#input\_delegate\_set\_name) | A reference name for the delegate set | `string` | `""` | no |
| <a name="input_delegation_enabled"></a> [delegation\_enabled](#input\_delegation\_enabled) | Do we need this sub-domain delegated from main apex domain | `bool` | `false` | no |
| <a name="input_dhcp_options_domain_name"></a> [dhcp\_options\_domain\_name](#input\_dhcp\_options\_domain\_name) | Specifies DNS name for DHCP options set | `string` | `""` | no |
| <a name="input_dhcp_options_domain_name_servers"></a> [dhcp\_options\_domain\_name\_servers](#input\_dhcp\_options\_domain\_name\_servers) | Specify a list of DNS server addresses for DHCP options set, default to AWS provided | `list(string)` | <pre>[<br/>  "AmazonProvidedDNS"<br/>]</pre> | no |
| <a name="input_dhcp_options_netbios_name_servers"></a> [dhcp\_options\_netbios\_name\_servers](#input\_dhcp\_options\_netbios\_name\_servers) | Specify a list of netbios servers for DHCP options set | `list(string)` | `[]` | no |
| <a name="input_dhcp_options_netbios_node_type"></a> [dhcp\_options\_netbios\_node\_type](#input\_dhcp\_options\_netbios\_node\_type) | Specify netbios node\_type for DHCP options set | `string` | `""` | no |
| <a name="input_dhcp_options_ntp_servers"></a> [dhcp\_options\_ntp\_servers](#input\_dhcp\_options\_ntp\_servers) | Specify a list of NTP servers for DHCP options set | `list(string)` | `[]` | no |
| <a name="input_dhcp_options_tags"></a> [dhcp\_options\_tags](#input\_dhcp\_options\_tags) | Additional tags for the DHCP option set | `map(string)` | <pre>{<br/>  "Component": "vpc"<br/>}</pre> | no |
| <a name="input_dx_connect_gateway_name"></a> [dx\_connect\_gateway\_name](#input\_dx\_connect\_gateway\_name) | The name of the Direct Connect Gateway to attach to | `string` | `""` | no |
| <a name="input_enable_dhcp_options"></a> [enable\_dhcp\_options](#input\_enable\_dhcp\_options) | Should be true if you want to specify a DHCP options set with a custom configuration | `bool` | `false` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Set to true to enable public DNS hostnames in the VPC | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Should be true to enable internal DNS support in the VPC | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Should be true if you want to provision NAT Gateways for each of your private networks | `bool` | `true` | no |
| <a name="input_external_nat_ip_ids"></a> [external\_nat\_ip\_ids](#input\_external\_nat\_ip\_ids) | List of EIP IDs to be assigned to the NAT Gateways (used in combination with reuse\_nat\_ips) | `list(string)` | `[]` | no |
| <a name="input_instance_tenancy"></a> [instance\_tenancy](#input\_instance\_tenancy) | A tenancy option for instances launched into the VPC | `string` | `"default"` | no |
| <a name="input_management_ingress_locations"></a> [management\_ingress\_locations](#input\_management\_ingress\_locations) | List of CIDR ranges for private ingress to resources | `list(string)` | `[]` | no |
| <a name="input_map_public_ip"></a> [map\_public\_ip](#input\_map\_public\_ip) | Map a public IP to instances in a public subnet | `bool` | `false` | no |
| <a name="input_private_app_subnets"></a> [private\_app\_subnets](#input\_private\_app\_subnets) | A list of private subnets to be used for app resource within this deployment | `list(string)` | `[]` | no |
| <a name="input_private_cache_subnets"></a> [private\_cache\_subnets](#input\_private\_cache\_subnets) | A list of private subnets to be used for cache storage within this deployment | `list(string)` | `[]` | no |
| <a name="input_private_db_subnets"></a> [private\_db\_subnets](#input\_private\_db\_subnets) | A list of private subnets to be used for db storage within this deployment | `list(string)` | `[]` | no |
| <a name="input_private_propagating_vgws"></a> [private\_propagating\_vgws](#input\_private\_propagating\_vgws) | A list of VGWs the private route table should propagate | `list(string)` | `[]` | no |
| <a name="input_private_route_table_tags"></a> [private\_route\_table\_tags](#input\_private\_route\_table\_tags) | Additional tags for the private route tables | `map(string)` | <pre>{<br/>  "Component": "route table"<br/>}</pre> | no |
| <a name="input_private_web_subnets"></a> [private\_web\_subnets](#input\_private\_web\_subnets) | A list of private subnets to be used for web resource within this deployment | `list(string)` | `[]` | no |
| <a name="input_public_apex_domain"></a> [public\_apex\_domain](#input\_public\_apex\_domain) | The public search domain suffix to create a zone for | `string` | n/a | yes |
| <a name="input_public_propagating_vgws"></a> [public\_propagating\_vgws](#input\_public\_propagating\_vgws) | A list of VGWs the public route table should propagate | `list(string)` | `[]` | no |
| <a name="input_public_route_table_tags"></a> [public\_route\_table\_tags](#input\_public\_route\_table\_tags) | Additional tags for the public route tables | `map(string)` | <pre>{<br/>  "Component": "route table"<br/>}</pre> | no |
| <a name="input_public_sub_domain"></a> [public\_sub\_domain](#input\_public\_sub\_domain) | The public search domain prefix to create a zone for | `string` | `""` | no |
| <a name="input_public_sub_domains"></a> [public\_sub\_domains](#input\_public\_sub\_domains) | A list of public search domain prefix to create zones for | `list(string)` | `[]` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of public subnets to be used for this deployment | `list(string)` | `[]` | no |
| <a name="input_r53_tags"></a> [r53\_tags](#input\_r53\_tags) | Additional tags for the Route53 Entries | `map(string)` | <pre>{<br/>  "Component": "vpc"<br/>}</pre> | no |
| <a name="input_reuse_nat_ips"></a> [reuse\_nat\_ips](#input\_reuse\_nat\_ips) | Should be true if you want to pass external NAT IPs in via the 'external\_nat\_ip\_ids' variable | `bool` | `false` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `bool` | `true` | no |
| <a name="input_subnet_tags"></a> [subnet\_tags](#input\_subnet\_tags) | Additional tags for the subnets | `map(string)` | <pre>{<br/>  "Component": "subnet"<br/>}</pre> | no |
| <a name="input_target_region"></a> [target\_region](#input\_target\_region) | The default region to build infrastructure in | `string` | `"eu-west-1"` | no |
| <a name="input_use_existing_zones"></a> [use\_existing\_zones](#input\_use\_existing\_zones) | Re-use existing public and private zones | `bool` | `false` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The VPC CIDR range for the new VPC | `string` | n/a | yes |
| <a name="input_vpc_endpoint_s3_app_enable"></a> [vpc\_endpoint\_s3\_app\_enable](#input\_vpc\_endpoint\_s3\_app\_enable) | Connect an S3 VPC Endpoint to the App subnets? | `bool` | `false` | no |
| <a name="input_vpc_endpoint_s3_enable"></a> [vpc\_endpoint\_s3\_enable](#input\_vpc\_endpoint\_s3\_enable) | Connect an S3 VPC Endpoint to the private route tables? | `bool` | `false` | no |
| <a name="input_vpc_endpoint_s3_web_enable"></a> [vpc\_endpoint\_s3\_web\_enable](#input\_vpc\_endpoint\_s3\_web\_enable) | Connect an S3 VPC Endpoint to the Web subnets? | `bool` | `false` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name of the VPC | `string` | n/a | yes |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | Additional tags for the VPC | `map(string)` | <pre>{<br/>  "Component": "vpc"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | The name of the db subnet group |
| <a name="output_delegate_set_id"></a> [delegate\_set\_id](#output\_delegate\_set\_id) | The ID of the delegate set |
| <a name="output_delegate_set_name_servers"></a> [delegate\_set\_name\_servers](#output\_delegate\_set\_name\_servers) | The Name Servers of the delegate set |
| <a name="output_private_name_servers"></a> [private\_name\_servers](#output\_private\_name\_servers) | The Name Servers of the private zone |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | The IDs of the Private Route Tables |
| <a name="output_private_zone_id"></a> [private\_zone\_id](#output\_private\_zone\_id) | The ID of the private zone |
| <a name="output_public_name_servers"></a> [public\_name\_servers](#output\_public\_name\_servers) | The Name Servers of the public zone |
| <a name="output_public_route_table_id"></a> [public\_route\_table\_id](#output\_public\_route\_table\_id) | The ID of the Public Route Table |
| <a name="output_public_zone_id"></a> [public\_zone\_id](#output\_public\_zone\_id) | The ID of the public zone |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
<!-- END_TF_DOCS -->
