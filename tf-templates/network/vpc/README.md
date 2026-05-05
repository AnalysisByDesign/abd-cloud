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
<!-- END_TF_DOCS -->
