# WP-04: ECS Cluster, Host ASG and Capacity Providers

**Repositories**: `abd-cloud` (primary); `abd-cloud-packer` if the ECS host AMI is baked rather than taken from the ECS-optimised AMI.
**Depends on**: WP-01 (private egress), WP-02 (ECR).
**Blocks**: WP-05 and the Tulox package.
**Protocol**: Discovery, then Clarify (stop), then Build. See the programme overview.

## Why

A new ECS cluster beside the current host, behind the same ALB, so sites move across one at a time by repointing listener rules. The current host keeps running until the last site has moved.

## Settled

- ECS on EC2, hosts in **private subnets**, bridge networking with **dynamic host ports** (`awsvpc` is ruled out by the ENI limits on small instances).
- Hosts come from the **existing ASG module**, extended rather than replaced.
- **The existing ALB only**: a new target group per service, and the listener rules stay pointed at the old host until each site's cutover.
- **Capacity provider 1**: on-demand, RI-covered instance family, `base = 1`.
- **Capacity provider 2** (spot burst): a later phase of this package, built only once two hosts have been proven to work. Valkey, the scheduler and one web task per site are pinned to on-demand.
- **Deployment circuit breaker with rollback** on every service.
- **Weekly instance refresh** of hosts, launching before terminating, around 04:00.
- EFS for uploads and application storage only, through **access points** per site.

## Phase 1: Discovery

1. The ASG module (as already mapped in WP-01, if that report exists): what it lacks for ECS, such as user data for cluster join, `protect_from_scale_in` for managed termination protection, capacity rebalance and mixed instances for the later spot provider, and the `AmazonECSManaged` tag.
2. The ALB: listeners, current rules per hostname, target group conventions, health check paths, and the security group relationship between ALB and host.
3. EFS: file system, current mount layout per site and for Tulox (including the `storage/app` symlink to `/mnt/efs/tulox.uk/storage`), ownership and UIDs, and existing access points.
4. RDS: instance class, `max_connections`, and whether WordPress and Tulox use separate users and schemas.
5. Secrets and configuration: how sites currently receive database credentials and application secrets (Secrets Manager, SSM, files baked into the AMI).
6. Logging and alerting conventions (CloudWatch log groups, retention, SNS topics).
7. The reserved instance and the current memory use per site (see the overview's facts to verify), leading to an instance type recommendation.
8. Whether any ECS, Cloud Map or Service Connect resources exist already.

## Phase 2: Clarify (minimum questions)

- **Host AMI**: the ECS-optimised Amazon Linux 2023 AMI by SSM parameter (no baking, patched by the weekly refresh), or a Packer-baked AMI built on it.
- **Instance type**: stay on `t3.small` within the RI, or move to `t3.medium` (a regional RI covers half). Present the measured memory numbers.
- **How tasks reach Valkey** across hosts: Cloud Map with SRV records (works with bridge mode and dynamic ports), Service Connect (adds an Envoy sidecar per task, which costs memory on small hosts), or Valkey on a fixed host port on the pinned on-demand host.
- **Module structure**: one ECS service module reused per site, or per-application stacks. Where task definitions live: here, or in each application repository with Terraform only owning the service shell. This is the biggest structural ruling in the programme.
- **Deployment ownership**: Terraform owns the service and ignores `task_definition` changes while CI registers new revisions and updates the service, or Terraform owns everything.
- **Nightly rollout trigger**: from each image's CI after push (at 04:00), or one orchestrating workflow.
- **Secrets injection**: ECS `secrets` from Secrets Manager or SSM Parameter Store, per the existing convention.
- **Log retention** period.

## Phase 3: Build scope

1. ASG module extensions for ECS hosts, each defaulting off.
2. ECS cluster, on-demand capacity provider with managed scaling, the host launch template, and the instance role.
3. Task execution role (ECR pull, logs, secrets) and a pattern for per-service task roles.
4. Security groups: ALB to hosts on the ephemeral port range; hosts to RDS, EFS and Valkey.
5. EFS access points per site, with UID and GID matching the image's non-root user from WP-03.
6. The service and target group pattern, proven with a trivial "hello" service routed through a **test hostname** on the existing ALB.
7. Container Insights or equivalent basic metrics, and alarms on service running count and deployment failure.
8. Weekly instance refresh schedule.
9. **Later phase**: the spot ASG and capacity provider (diversified instance types, `price-capacity-optimized`, `ECS_ENABLE_SPOT_INSTANCE_DRAINING=true`), placement constraints pinning the critical tasks to on-demand, and scheduled scaling for Friday and Saturday evenings with target tracking as a backstop.

## Out of scope

- Moving any real site (WP-05, Tulox package).
- Self-hosted runners (WP-07).
- Deleting the old host or the POC ECR repository; that closes out the programme.

## Done when

- The hello service is reachable through the existing ALB on a test hostname, survives a host instance refresh with no failed requests, and a deliberately broken deployment is rolled back automatically by the circuit breaker.
- Every existing caller of the extended modules plans with no diff.
