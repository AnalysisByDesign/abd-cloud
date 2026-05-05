# template: compute/ec2-asg

Provisions a complete EC2-based application tier: launch template, Auto Scaling Group, Application Load Balancer, SSL certificate, Route53 DNS record, SQS queue, security groups, and an IAM instance profile.

## Resources Provisioned

- **Launch template** — AMI, instance type, EBS volumes, IAM profile, user data script (rendered via `templatefile()`), and security group assignment
- **Auto Scaling Group** — Min/max/desired counts, VPC subnet placement, health check configuration, and target group attachment
- **ALB** — Internet-facing with HTTPS listener, HTTP redirect, and target group; optional WAFv2 association
- **SSL certificate** — ACM certificate validated via Route53 DNS records
- **Route53** — Alias record from the application domain to the ALB
- **SQS** — Application event queue with optional DLQ
- **Security groups** — ALB, application, and inter-tier rules
- **IAM** — Instance profile role with configurable policies for S3, SSM, and SQS access

## Notes

- The user data script is rendered from a template file at `var.user_data_script_folder/var.user_data_script`. The template receives `env` and `name` variables.
- The IAM policy document template at `var.ec2_policy_template_folder/var.ec2_policy_template` receives `s3_name` and `ssm_key_prefix` variables.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
