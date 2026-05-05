# template: compute/ecs-cluster

Provisions an ECS cluster as a named logical grouping for container workloads. Supports both EC2 and Fargate launch types.

## Resources Provisioned

- **ECS cluster** — Named cluster with configurable capacity provider settings

## Notes

Create the ECS cluster before deploying any ECS services or Fargate tasks that reference it. The cluster itself has no direct cost — billing occurs only when tasks run on it.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
