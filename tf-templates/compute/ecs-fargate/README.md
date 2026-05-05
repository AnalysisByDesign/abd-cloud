# template: compute/ecs-fargate

Provisions a complete ECS Fargate application tier: task definition, ECS service, Application Load Balancer, SSL certificate, Route53 DNS record, SQS queue, security groups, and a task IAM role.

## Resources Provisioned

- **ECS task definition** — Container definitions rendered from a JSON template file; CPU, memory, and IAM roles configurable
- **ECS service** — Desired count, Fargate network configuration (subnets, security groups), and ALB target group attachment
- **ALB** — Internet-facing with HTTPS listener, HTTP redirect, and target group
- **SSL certificate** — ACM certificate validated via Route53 DNS records
- **Route53** — Alias record from the application domain to the ALB
- **SQS** — Application event queue with optional DLQ
- **Security groups** — ALB and ECS task security groups with inter-tier rules
- **IAM** — Task execution role (for ECR pull and CloudWatch log write) and task role (for application-level AWS access)

## Notes

- The task container definitions are rendered from `var.tasks_folder/var.tasks_file` via `templatefile()`. The template receives `container_name`, `docker_image`, `aws_region`, `log_group`, and `sqs_queue_url`.
- Fargate requires `awsvpc` network mode; the service receives an ENI directly and security groups are applied at the task level, not the host level.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
