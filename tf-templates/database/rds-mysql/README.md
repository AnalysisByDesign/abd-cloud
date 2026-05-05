# template: database/rds-mysql

Provisions a single-instance MySQL RDS database with a parameter group, DB subnet group, enhanced monitoring, and security groups.

## Resources Provisioned

- **RDS instance** — MySQL engine, storage type and size, instance class, multi-AZ option, KMS encryption, automated backups
- **Parameter group** — Custom MySQL parameter group
- **DB subnet group** — Multi-AZ subnet placement
- **Security groups** — Database security group with ingress from the application tier
- **IAM role** — Enhanced monitoring role for CloudWatch metrics at sub-minute intervals

## Notes

- Enhanced monitoring publishes OS-level metrics (CPU steal, disk I/O, memory) to CloudWatch at 1–60 second granularity.
- For production workloads that require high availability, prefer `database/rds-aurora` which provides native clustering and automated failover.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
