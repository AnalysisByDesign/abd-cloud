# template: storage/object

Provisions an S3 bucket via the `storage/aws-s3` module with configurable policy, lifecycle rules, versioning, logging, and transfer acceleration.

## Resources Provisioned

- **S3 bucket** — With KMS server-side encryption always enabled
- **Bucket policy** — Rendered from a template file in `var.policy_folder/var.policy_file`, receiving `s3_name` and `account_id` as template variables; falls back to `var.s3_policy` if set directly
- **Optional features** — Versioning, access logging, lifecycle rules, and transfer acceleration, each enabled by the corresponding variable

## Notes

- The bucket policy template mechanism allows complex policies (cross-account access, CloudTrail delivery restrictions, etc.) to be managed as separate JSON template files rather than inline HCL.
- When `s3_logging` is set, the target logging bucket must already exist and have the `log-delivery-write` ACL or equivalent bucket policy.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
