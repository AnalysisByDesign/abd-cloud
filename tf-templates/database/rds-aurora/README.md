# template: database/rds-aurora

Provisions an Aurora RDS cluster with configurable engine (MySQL or PostgreSQL), cluster parameter group, instance parameter group, DB subnet group, and security groups.

## Resources Provisioned

- **Aurora cluster** — Engine version, master credentials, KMS encryption, backup retention, maintenance window, deletion protection
- **Aurora instances** — One or more instances (typically one writer, optional readers) in the cluster; instance class configurable
- **Parameter groups** — Cluster parameter group (character set, collation, timezone) and instance parameter group (query cache, slow query log, connection limits)
- **DB subnet group** — Multi-AZ subnet placement
- **Security groups** — Database tier security group with ingress rules from the application security group

## Notes

- Snapshot restoration is supported via `snapshot_identifier`. If set, the master password input is ignored (the password from the snapshot is used).
- IAM database authentication can be enabled for passwordless connections from EC2 instances with the appropriate IAM policy.
- The cluster and instance engine version should be kept in sync — mismatches between `engine_version` and the `db_family` in the parameter groups will cause plan errors.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
