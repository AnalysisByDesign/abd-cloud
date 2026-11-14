# Container Platform Migration: Programme Overview

**Created**: 2026-11-10
**Source**: Planning session with Dave, 2026-11-10 (text, then voice on the dog walk).
**Status**: In progress. WP-01, WP-02 and WP-03 complete (2026-11-11); WP-04 complete (2026-11-13); WP-05 complete (2026-11-14). Tulox next, then step 7.

## How to use this set

Give each agent this overview plus its own work package. Each package runs inside one repository and follows the three-phase protocol below. No agent starts building until Dave has ruled on the Clarify questions.

| File | Repository | Step |
|---|---|---|
| `wp-01-nat-instance-and-s3-endpoint.md` | `abd-cloud` | 1 |
| `wp-02-ecr-and-ci-access.md` | `abd-cloud` | 2 |
| `wp-03-container-base-images.md` | `abd-cloud-containers` | 2 |
| `wp-04-ecs-cluster-and-capacity.md` | `abd-cloud`, `abd-cloud-packer` | 3 |
| `wp-05-wordpress-containerisation.md` | images repo, `abd-cloud-packer`, `abd-cloud` | 4 and 5 |
| Tulox session brief (`docs/sessions/2026-11-10-container-platform-migration.md`) | `tulox` | 6 |
| `wp-07-spot-github-runners.md` | `abd-cloud` | Parked |
| `wp-08-wordpress-edit-copies.md` | `abd-cloud-containers`, `abd-cloud-params` | Parked; on demand, after WP-05 |

Step 7, retiring the old host, the NAT gateway remnants and the POC ECR repository, closes out the programme. It follows WP-05, and WP-04's status section holds the notes for the ALB transition.

## Three-phase protocol (applies to every package)

### Phase 1: Discovery (read-only)

- Change nothing. The only file written is the discovery report.
- Allowed: reading code, `terraform fmt -check`, `terraform validate`, `packer validate`, and read-only AWS `describe`/`list`/`get` calls if credentials are supplied. No `apply`, no `plan -out`, and no AWS write calls.
- Map what exists: modules and their inputs and outputs, callers, state layout, naming, tagging, variable style, file layout, CI workflows, and anything that already half-does the job.
- Write the report to the repository's conventional docs location, or `docs/discovery/<wp-id>.md` if there is none. It covers current state with file paths, observed conventions, gaps against the target, risks, a proposed approach, and the question list for Phase 2.

### Phase 2: Clarify

- Put every question to Dave, each with options and a recommendation, then **stop**.
- Structural choices are always Dave's: module boundaries, whether to extend or create a module, naming, file and directory layout, variable shapes, and repository placement. Never decide these by default, even when one answer looks obvious.
- Rulings are recorded in the work package under `## Rulings` before Phase 3 starts.

### Phase 3: Build

- Extend existing modules in preference to creating new ones, unless a ruling says otherwise.
- Module changes are backward compatible: new inputs default to current behaviour, so every existing caller plans with **no diff**. Prove it by running `plan` on the unchanged callers.
- Show the `terraform plan` to Dave; Dave applies.
- Small, reviewable PRs with Conventional Commits.
- If a discovery assumption turns out wrong, stop and go back to Clarify rather than improvising.

## Target state

```text
Internet
  -> ALB (existing, one only; host-header listener rule per site)
       -> target groups (bridge mode, dynamic host ports)
            -> ECS cluster "prod", EC2 capacity in private subnets
                 capacity provider 1: on-demand ASG (RI-covered base, min 1)
                 capacity provider 2: spot ASG (burst only, min 0)  [later]
                 services: one per WordPress site, Tulox web, worker,
                           scheduler, Reverb, Valkey (pinned on-demand)
Private subnets egress
  -> fck-nat instance, ASG of one, public subnet (route-flip replacement)
  -> S3 gateway endpoint (free) for S3 and ECR layer pulls
Shared: RDS (unchanged), EFS (uploads and storage only), SQS, ECR
CI: GitHub Actions -> ECR (OIDC); nightly rebuilds; 04:00 rollouts
```

## Settled decisions (do not relitigate)

1. **ECS on EC2**, not EKS (control plane cost) and not Fargate (per-task cost, roughly $80 to $100 a month for about eleven tasks). Revisit Fargate when the RI expires.
2. **Keep the existing single ALB.** Migrate site by site by repointing each listener rule; weighted target groups allowed for canarying. No second ALB, and no DNS flip.
3. **Replace the NAT gateway with a fck-nat instance** on the smallest viable instance (t4g.nano), as an ASG of one in a public subnet. Replacement uses a **route flip**: the new instance boots, becomes healthy, then repoints the private route tables to itself. The old instance stays alive a few minutes for in-flight connections. Planned refreshes have no outage; only an unplanned failure has a short gap, which is accepted.
4. **S3 gateway endpoint** added to the existing VPC module.
5. **Layered images in a new dedicated repository**: an Analysis by Design base, then a pinned PHP layer, then Laravel and WordPress layers. **Debian slim** for the PHP line (Alpine rejected for PHP because of musl performance issues). Valkey uses the official Alpine image, not the base.
6. **WordPress code is immutable in the image.** Per-site manifests apply at **build** time, not boot. `DISALLOW_FILE_MODS` is set, so WordPress's own auto-update is off. Only uploads live on EFS.
7. **Nightly rebuild and rollout** of container images at around 04:00, gated on a smoke test. ECS's deployment circuit breaker keeps the old tasks if the new ones fail health checks.
8. **Weekly instance refresh** of ECS hosts and of the NAT instance, launching the replacement before terminating the old one. This doubles as a recovery drill.
9. **ECR plus GitHub Actions** for image storage and builds. A fresh, codified ECR replaces the manual Tulox POC repository, which is retired separately.
10. **Queues move to SQS** (long polling). Cache, sessions, locks and Reverb scaling use **Valkey** as a pinned container until ElastiCache is justified.
11. **Spot is for burst only**: an on-demand base of one (RI-covered) plus spot above it, with Valkey, the scheduler and one web task per site pinned to on-demand. Scheduled scale-out on Friday and Saturday evenings, with target tracking as a backstop.
12. **Local development mirrors production**: the same images run under Compose on the laptop (Docker Desktop) and the Mac mini (Colima), with a dev override for bind mounts and hot reload. `make dev` stays the entry point. The mflux image workers on the mini stay native.
13. **Self-hosted runners stay parked** until free Actions minutes run out. When built, they get their own cluster and spot-only ASG, never shared with production.

## Facts to verify in discovery, not assume

- **Production host**: confirmed in WP-03 discovery (2026-11-10) as a `t4g.medium` (Graviton, **arm64**) in the `abd-wordpress` ASG, from the arm64 `abd-wp-php83-*` AMI (`abd-cloud-params/abd-wordpress/wordpress-vpc/app.wordpress/app_config.tfvars`). It is shared by Tulox, nine WordPress sites and `mortgage.daverix.ai`. Production therefore matches both Macs (arm64). Images are built for `linux/arm64` only (WP-03 ruling 24). The earlier record of a `t3.small` (amd64) was wrong.
- **Reserved instance**: whether one exists, plus its family, size, scope (regional or zonal), class (standard or convertible) and end date. It shapes the instance type. An RI in the `t3` family would not cover the current `t4g` host.
  ```bash
  aws ec2 describe-reserved-instances --filters Name=state,Values=active \
    --query 'ReservedInstances[].{Type:InstanceType,Scope:Scope,Class:OfferingClass,End:End,Count:InstanceCount}'
  ```
- **Memory headroom**: the current `t4g.medium` (4 GiB) has to hold nine WordPress tasks (some can be disabled in ECS), `mortgage.daverix.ai`, Tulox web, worker, scheduler and Reverb, and Valkey. Measure the current resident memory per site before sizing.
- **Region**: eu-west-1.
- **Current NAT**: the number of NAT gateways (one per AZ or a single one), and whether any third party allow-lists the NAT's Elastic IP.

## Cost guardrails

- Nothing that adds recurring cost above roughly £5 a month without a ruling from Dave.
- Explicitly excluded: interface VPC endpoints, a second ALB, RDS Proxy, EKS, and Fargate.
- The overlap period with two hosts running is not covered by the RI, so keep it to weeks, not months.
- Release any Elastic IP left idle after the NAT gateway is removed, because idle EIPs are charged.

## House style for all documents produced

British English. No em dashes or en dashes anywhere; use commas, colons, semicolons, full stops or parentheses.
