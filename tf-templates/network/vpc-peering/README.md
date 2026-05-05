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
<!-- END_TF_DOCS -->
