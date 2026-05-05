# template: account

Provisions account-level resources that are shared across all workloads in an AWS account. Run once per account during initial bootstrap, and re-applied when account-level configuration changes.

## Resources Provisioned

- **IAM roles** — RDS enhanced monitoring role, cross-account administrator access role, and (in the management account only) a GitHub Actions OIDC provider and IAM role for CI/CD
- **Route53** — Public hosted zone with a reusable delegation set; optional sub-domain delegation from an apex domain in another account; MX records for email routing
- **ECR** — Optional Docker repository with configurable lifecycle policy
- **CloudWatch** — Log groups for infrastructure, web, and application tiers
- **New Relic** — Optional monitoring integration role

## Bootstrap Order

This template must be applied before any other template in the account, as other templates depend on resources created here (IAM roles, DNS zones, log groups). In the management account (`abd-global`), apply this template first to create the GitHub Actions OIDC role used by all subsequent automated runs.

## Notes

- The GitHub Actions OIDC role is only created when `github_org` is non-empty. Set it in the management account config only; leave it empty in all other accounts.
- DNS delegation from an apex domain in another account requires that account's zone to already exist and be accessible via the cross-account `terraform` role.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
