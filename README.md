# abd-cloud

Terraform templates for the AbD Cloud infrastructure platform. Templates consume child modules from `abd-cloud-modules` and environment-specific configuration from `abd-cloud-params`, then provision infrastructure into one or more AWS accounts via cross-account role assumption.

## How It Works

```
abd-cloud-params/          Config files (tfvars + shell scripts) — the "what"
abd-cloud/                 Terraform templates — the "how"
  └── tf-templates/
abd-cloud-modules/         Reusable child modules — the "building blocks"
```

### Running a build

```bash
# Plan a single resource
./tf-run.sh plan /path/to/abd-cloud-params/abd-wordpress/wordpress-vpc

# Apply a single resource
./tf-run.sh apply /path/to/abd-cloud-params/abd-wordpress/wordpress-vpc

# Dry-run (show terraform commands without executing)
./tf-run.sh -d plan /path/to/abd-cloud-params/abd-wordpress/wordpress-vpc

# Run the full stack in priority order
./tf-run-all.sh apply
```

`tf-run.sh` reads the `*_config.sh` and `*.tfvars` files from the target path outward to the params root, then runs Terraform against the appropriate template. State is stored in S3 (`abd-tf-state`) with DynamoDB locking.

## Template Catalogue

### Account
| Template | Description |
|----------|-------------|
| [account](tf-templates/account/) | Account-level IAM roles, ECR repository, CloudWatch log groups, Route53 delegation, and optional GitHub Actions OIDC role |

### Compute
| Template | Description |
|----------|-------------|
| [compute/ec2-asg](tf-templates/compute/ec2-asg/) | EC2 Auto Scaling Group with launch template, ALB, SSL cert, Route53, SQS queue, and IAM instance profile |
| [compute/ecs-cluster](tf-templates/compute/ecs-cluster/) | ECS cluster for Fargate or EC2 container workloads |
| [compute/ecs-fargate](tf-templates/compute/ecs-fargate/) | ECS Fargate service with ALB, SSL cert, Route53, SQS queue, and task IAM role |

### Database
| Template | Description |
|----------|-------------|
| [database/rds-aurora](tf-templates/database/rds-aurora/) | Aurora MySQL or PostgreSQL cluster with parameter groups, subnet group, and security groups |
| [database/rds-mysql](tf-templates/database/rds-mysql/) | Single MySQL RDS instance with parameter group, enhanced monitoring, and security groups |
| [database/dynamodb](tf-templates/database/dynamodb/) | DynamoDB table via module invocation |

### Network
| Template | Description |
|----------|-------------|
| [network/vpc](tf-templates/network/vpc/) | Full VPC stack: subnets across 3 AZs, route tables, IGW, NAT gateways, VPC endpoints, DB/cache subnet groups, and parameter groups |
| [network/vpc-peering](tf-templates/network/vpc-peering/) | Cross-account VPC peering with automatic acceptance and route table updates |
| [network/wp-dns](tf-templates/network/wp-dns/) | WordPress-specific DNS: hosted zone, ALB alias records, www redirect, MX records, and ACM SSL certificate |

### Management
| Template | Description |
|----------|-------------|
| [management/cloudtrail](tf-templates/management/cloudtrail/) | CloudTrail trail with dedicated S3 bucket and bucket policy |

### Security
| Template | Description |
|----------|-------------|
| [security/secrets](tf-templates/security/secrets/) | SSM Parameter Store secrets for application credentials |

### Storage
| Template | Description |
|----------|-------------|
| [storage/object](tf-templates/storage/object/) | S3 bucket with configurable policy, lifecycle rules, versioning, and logging |
| [storage/efs](tf-templates/storage/efs/) | EFS file system with security groups, mount targets, and Route53 DNS record |

## AWS Accounts

| Account | ID | Purpose |
|---------|-----|---------|
| `abd-global` | 813984516777 | Shared services: CloudTrail hub, Terraform state, S3 access logs, services VPC |
| `abd-wordpress` | 800653036500 | WordPress hosting: VPC, RDS Aurora, EFS, EC2 ASG, 8 hosted domains |

Both accounts are managed by assuming `arn:aws:iam::{account_id}:role/terraform` via the management account credentials.

## State Management

Terraform state is stored in the S3 bucket `abd-tf-state` (in `abd-global`) with DynamoDB table `terraform-state-lock` for concurrency control. Each resource has a unique state key derived from the account name and `statefile_basename` configured in its `*_config.sh`.

## Requirements

| Tool | Version |
|------|---------|
| Terraform | >= 1.9.0 |
| AWS Provider | ~> 5.0 |

## Pre-commit

```bash
pip install pre-commit
pre-commit install
```

Runs `terraform fmt` on changed template files and `terraform-docs` to keep READMEs current. See [.pre-commit-config.yaml](.pre-commit-config.yaml).
