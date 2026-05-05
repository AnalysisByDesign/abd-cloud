# template: management/cloudtrail

Provisions an AWS CloudTrail trail with a dedicated S3 bucket and bucket policy for storing audit logs.

## Resources Provisioned

- **CloudTrail trail** — Multi-region trail recording management and data events; configurable for hub (organisation-level) or spoke (single-account) mode
- **S3 bucket** — Dedicated bucket for CloudTrail log delivery with configurable lifecycle rules for log retention and archival
- **S3 bucket policy** — Allows CloudTrail to check bucket ACL and deliver logs; denies all non-HTTPS access

## Notes

- In the `abd-global` management account this trail is the centralised hub, configured to receive logs from all accounts in the organisation.
- Each workload account (`abd-wordpress`, etc.) has its own spoke trail that delivers logs to that account's CloudTrail bucket.
- Bucket policy is rendered from a template file to include the correct account IDs and trail ARN.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
