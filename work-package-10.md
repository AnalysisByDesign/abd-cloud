# Work Package 10 — GitHub Actions OIDC Deploy Role (abd-cloud Terraform)

**Target repos:** abd-cloud Terraform (wherever IAM and OIDC resources live)
**Prepared by:** Claude (via the abd-cloud-packer project session)

---

## STOP — Read this before touching anything

This work package is **purely additive**. No existing resources are modified. It adds:
1. A GitHub Actions OIDC identity provider (one per AWS account — skip if it already exists)
2. An IAM role that GitHub Actions can assume when deploying the property-calculator app

Do not apply this Terraform until the `composer.lock` fix and `.github/workflows/deploy.yml`
are committed and pushed in the property-calculator repo (Work Package 9). The workflow
will fail immediately if the role doesn't exist, but it will also fail if `composer.lock`
causes `composer install` to abort on the instance.

---

## Context

`mortgage.daverix.ai` runs as a Laravel app on the EC2 instance in the `wordpress` Auto
Scaling Group. Deploys are triggered by pushing to `main` on the property-calculator repo.
GitHub Actions authenticates with AWS using OIDC (no stored credentials) and calls
AWS SSM Run Command to execute `/usr/local/bin/mortgage-deploy.sh` on the running instance.

The instance's own IAM role already has `ssm:GetParameter` and `ssm:SendCommand`-receive
rights — those are handled by the existing instance profile. This work package only creates
the **caller-side** role that GitHub Actions assumes.

AWS account: `800653036500`
Region: `eu-west-1`

---

## Part 1 — GitHub Actions OIDC provider

**Check first:** there can only be one `aws_iam_openid_connect_provider` per issuer URL
per account. If an OIDC provider for `token.actions.githubusercontent.com` already exists
in this account (e.g. from another GitHub Actions integration), do not create a second one.
Instead, reference the existing one with a `data` source (see note below).

### New resource (if provider does not already exist)

```hcl
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # AWS validates the GitHub OIDC certificate chain directly via its trust store.
  # The thumbprint is still required by the API but is not used for verification.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea"]
}
```

### If the provider already exists — use a data source instead

```hcl
data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}
```

Then reference `data.aws_iam_openid_connect_provider.github_actions.arn` (instead of
`aws_iam_openid_connect_provider.github_actions.arn`) in the trust policy below.

---

## Part 2 — IAM role for property-calculator deploys

This role is assumed only by GitHub Actions running on the `main` branch of the
`AnalysisByDesign/property-calculator` repo.

### Trust policy document

```hcl
data "aws_iam_policy_document" "github_deploy_property_calculator_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
      # If using the data source above:
      # identifiers = [data.aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:AnalysisByDesign/property-calculator:ref:refs/heads/main"]
    }
  }
}
```

### IAM role

```hcl
resource "aws_iam_role" "github_deploy_property_calculator" {
  name               = "github-deploy-property-calculator"
  assume_role_policy = data.aws_iam_policy_document.github_deploy_property_calculator_trust.json

  tags = {
    ManagedBy   = "terraform"
    Purpose     = "GitHub Actions deploy role for property-calculator"
    Repo        = "AnalysisByDesign/property-calculator"
  }
}
```

### Permissions policy

Minimal permissions: discover the instance by tag, send a command to it, and read the result.

```hcl
data "aws_iam_policy_document" "github_deploy_property_calculator_perms" {
  # Find the running instance by tag — no resource filter possible for Describe
  statement {
    sid       = "DescribeInstances"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }

  # Send SSM Run Command to instances tagged Stack=wordpress only
  statement {
    sid     = "SSMSendCommand"
    effect  = "Allow"
    actions = ["ssm:SendCommand"]

    resources = [
      "arn:aws:ec2:eu-west-1:800653036500:instance/*",
      "arn:aws:ssm:eu-west-1::document/AWS-RunShellScript",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Stack"
      values   = ["wordpress"]
    }
  }

  # Read command results — needed for wait + get-command-invocation
  statement {
    sid    = "SSMReadResults"
    effect = "Allow"
    actions = [
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_deploy_property_calculator" {
  name   = "github-deploy-property-calculator-inline"
  role   = aws_iam_role.github_deploy_property_calculator.id
  policy = data.aws_iam_policy_document.github_deploy_property_calculator_perms.json
}
```

---

## Part 3 — Output the role ARN

Add an output so the ARN is easy to retrieve (needed for the workflow file in
property-calculator):

```hcl
output "github_deploy_property_calculator_role_arn" {
  value       = aws_iam_role.github_deploy_property_calculator.arn
  description = "IAM role ARN for GitHub Actions → property-calculator deploys. Put this in .github/workflows/deploy.yml."
}
```

Expected value: `arn:aws:iam::800653036500:role/github-deploy-property-calculator`

---

## Part 4 — Update the deploy workflow (back in property-calculator)

Once this Terraform is applied, replace `<ACCOUNT_ID>` in `.github/workflows/deploy.yml`:

```yaml
role-to-assume: arn:aws:iam::800653036500:role/github-deploy-property-calculator
```

---

## Verification

After `terraform apply`:

```bash
# Confirm the role exists
aws iam get-role --role-name github-deploy-property-calculator \
  --query 'Role.{ARN:Arn,Trust:AssumeRolePolicyDocument}' \
  --output json

# Confirm the OIDC provider exists
aws iam list-open-id-connect-providers --output json

# Once deploy.yml is committed and a push to main happens,
# the GitHub Actions workflow should show "Configure AWS credentials" passing.
```

After the first successful deploy:

```bash
# Check the most recent SSM command on the instance
aws ssm list-command-invocations \
  --filters "key=DocumentName,value=AWS-RunShellScript" \
  --details \
  --query 'CommandInvocations[0].{Status:Status,Output:CommandPlugins[0].Output}' \
  --output json
```

---

## Out of scope

- Changes to existing instance profiles or IAM roles
- RDS security group rules or network changes
- Any Terraform for the WordPress sites or EFS
- The SSM parameters (`/laravel/mortgage.daverix.ai/env`, `/laravel/mortgage.daverix.ai/deploy-key`) — these already exist
