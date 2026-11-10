# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository role

This repo holds the Terraform **templates** ("the how") for the AbD Cloud platform. It is one of three sibling repos that must be checked out side by side:

```
../abd-cloud-params/    tfvars + *_config.sh per resource, plus sequence/*.csv ("the what")
./                      tf-templates/ + wrapper scripts ("the how")
../abd-cloud-modules/   reusable child modules, referenced by relative path
```

Templates reference modules with relative paths such as `source = "../../../../abd-cloud-modules/security/security-group"`, so the sibling layout is required. CI (`.github/workflows/`) reproduces it by checking all three repos out under `$GITHUB_WORKSPACE`.

The `abd-global/` and `abd-wordpress/` directories in this repo hold only `build.log` output from `tf-run-all.sh`. They are not config; the real config lives in `../abd-cloud-params/`.

## Running Terraform

Never run `terraform` directly in a template directory. Always go through the wrapper scripts from the repo root, with credentials from `aws-vault` using the `abd_global` profile (this applies to every account, because all access is by role assumption from the management account):

```bash
# Single resource: init / plan / apply / dry-run (prints the terraform commands only)
aws-vault exec abd_global -- ./tf-run.sh -v ../abd-cloud-params/abd-wordpress/wordpress-vpc/app.wordpress init
aws-vault exec abd_global -- ./tf-run.sh    ../abd-cloud-params/abd-wordpress/wordpress-vpc/app.wordpress plan
aws-vault exec abd_global -- ./tf-run.sh    ../abd-cloud-params/abd-wordpress/wordpress-vpc/app.wordpress apply
aws-vault exec abd_global -- ./tf-run.sh -d ../abd-cloud-params/abd-wordpress/wordpress-vpc/app.wordpress plan

# Other terraform subcommands pass through
./tf-run.sh <param-path> state list
./tf-run.sh <param-path> import aws_cloudtrail.this my-trail

# Everything under a params subtree, in sequence order
aws-vault exec abd_global -- ./tf-run-all.sh ../abd-cloud-params/abd-global apply
aws-vault exec --region=eu-west-1 abd_global -- ./tf-run-all.sh -c -v ../abd-cloud-params/abd-global init -upgrade
```

`tf-run.sh` flags: `-c` clean `.terraform` cache, `-d` dry-run, `-o` override the `protect` flag on destroy, `-t n` terraform parallelism, `-v`/`-vv` verbose (`-vv` sets `TF_LOG=INFO`). `apply` runs with `-auto-approve`, so run `plan` first.

## How tf-run.sh wires things together

1. It walks up from the target path to find `global_config.sh`, which marks the params root.
2. It sources `global_config.sh`, then each `*_config.sh` in every directory from the root down to the target, and adds every `*.tfvars` it finds on that path as `-var-file`. Deeper files override shallower ones.
3. The config scripts set shell variables that the wrapper uses: `acct_target` (plus `acct_billing`/`acct_apex`/`acct_auth`, exported as `TF_VAR_*`), `build_resources` (template paths relative to `tf-templates/`, or `here` to run Terraform inside the params dir itself), `statefile_basename`, and the lock settings.
4. `TF_DATA_DIR` is set to `<param-path>/.terraform`, so one template can serve many param targets without sharing a cache.
5. State lives in S3 bucket `abd-tf-state` at key `<account_name>/<statefile_basename>.tfstate`, using native S3 lockfiles. The backend assumes `role/terraform` in the management account, written to a temp HCL file because Terraform 1.10+ needs an `assume_role` block.
6. `TF_VAR_account_name` comes from looking up `acct_target` in `acct_list`. The run aborts if the account is not listed there.

`tf-run-all.sh` reads `sequence/*.csv` in the params repo (`seq,protect,prevent,path`). Rows run in ascending `seq` order (descending for `destroy`). Rows with the same `seq` run in parallel (`-m`, default 8). A row with `prevent` set is always skipped, and one with `protect` set is skipped on destroy.

## Template conventions

- Each template is a flat root module under `tf-templates/<category>/<name>/`.
- Files named `common-*.tf` are **symlinks** into `tf-templates/common/` (providers, common variables, VPC data source, subdomain delegation). Edit the file in `common/`, not the symlink, and remember that a change there affects every template that links it. A new template should symlink the common files it needs in the same way.
- `common/providers.tf` pins Terraform `~> 1.15.0` (`.terraform-version` = 1.15.4, `.terragrunt-version` is also present) and AWS provider `~> 6.0`. The provider assumes `arn:aws:iam::${var.acct_target}:role/${var.acct_target_role}` (default role `terraform`). The default region is `eu-west-1`.
- Every template requires the common tagging variables (`account_name`, `common_tag_*`) declared in `common/variables.tf`. Their values come from the params tfvars.
- Files ending in `.tfx` are disabled templates that Terraform ignores. Rename one to `.tf` to enable it.
- Opt-in features are gated with `count = <toggle> ? 1 : 0`. The toggle is either a bool (`enable_www_redirect`, `wildcard_dns_enabled`) or a non-empty string (`dns_challenge_user_name != ""`) that defaults to off. See `network/dns/web.tf` and `network/dns/dns-challenge-user.tf`.

## Linting and docs

Pre-commit (`pre-commit install`, or run it once with `pre-commit run --all-files`) runs:
- `terraform_fmt` on templates
- `terraform_docs`, which injects tables between `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` in each template's `README.md` (config: `.terraform-docs.yml`). Don't hand-edit inside those markers.
- `shellcheck --severity=warning` on `*.sh` (exclusions are in `.shellcheckrc`)

To validate a template, use `./tf-run.sh <param-path> validate`. There are no unit tests.

## CI

- `terraform-plan.yml` runs plan, `terraform-apply.yml` applies on push to `main` (or for a single resource via `workflow_dispatch`), and `terraform-drift.yml` runs a weekly drift check.
- The workflows authenticate by OIDC as `github-actions-terraform` in the management account.
- `terraform-apply.yml` hardcodes one job per resource, chained with `needs:` in priority order. When you add a resource to the params sequence, also add a job here.
- `terraform-apply.yml` still pins `terraform_version: "~1.9"`, while `common/providers.tf` requires `~> 1.15.0` and the plan workflow uses `~1.15`.

## Accounts

| Account | Purpose |
|---------|---------|
| `abd-global` | Shared services: CloudTrail hub, Terraform state bucket, S3 access logs, services VPC |
| `abd-wordpress` | WordPress hosting: VPC, RDS Aurora, EFS, EC2 ASG, hosted sites |

Account IDs are in `README.md` and the params repo's `acct_list`.
