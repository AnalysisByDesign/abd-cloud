# template: security/secrets

Provisions SSM Parameter Store secrets for application credentials, with lifecycle protection to preserve values updated outside of Terraform.

## Resources Provisioned

- **SSM Parameters (SecureString)** — One or more secrets; typically RDS master username and password for a database instance

## Notes

- Initial values are set at creation time from the tfvars. Subsequent `terraform apply` runs will not overwrite values — any rotation or update made by operators or automated tooling is preserved.
- To force a value change through Terraform, the parameter must be tainted (`terraform taint`) or manually deleted before applying.
- Secret ARNs can be passed to EC2 user data or ECS task definitions to enable application-level secret retrieval without embedding credentials in configuration files.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
