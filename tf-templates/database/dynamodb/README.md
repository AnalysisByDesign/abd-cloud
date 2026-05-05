# template: database/dynamodb

Provisions a DynamoDB table via the `database/dynamodb` module. Used for application-level data storage with configurable key schema, capacity, and TTL.

## Resources Provisioned

- **DynamoDB table** — Hash key, optional range key, read/write capacity, TTL attribute, and tags

## Notes

This template is distinct from the `database/dynamodb/terraform` bootstrap resource in `abd-cloud-params`, which creates the Terraform state lock table. This template is for application data tables.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
