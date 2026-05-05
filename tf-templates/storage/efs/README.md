# template: storage/efs

Provisions an EFS file system with mount targets in each private subnet, a Route53 DNS record for discovery, and security groups controlling NFS access.

## Resources Provisioned

- **EFS file system** — Performance mode, throughput mode, and optional KMS encryption; lifecycle policy to transition infrequently accessed files to EFS-IA storage class
- **Mount targets** — One per subnet (typically one per AZ), allowing instances in those subnets to mount the file system
- **Security groups** — EFS security group accepting NFS (port 2049) from the application tier security group
- **Route53 record** — CNAME in the private hosted zone pointing to the EFS file system's DNS name for stable, human-readable access

## Notes

- EFS is used as shared persistent storage for WordPress media uploads, allowing the WordPress application tier to scale horizontally without each instance maintaining its own media store.
- Mount target security groups must allow outbound NFS from the EC2/ECS security group and inbound NFS to the EFS security group.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
