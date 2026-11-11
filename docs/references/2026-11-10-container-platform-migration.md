---
session: 2026-11-10 container platform migration
date: 2026-11-10
status: unprocessed
---

# Session Brief: Container Platform Migration

**Source**: Planning session with Dave, 2026-11-10 (text, then voice).

The session moved the shared hosting estate (Tulox plus five or six WordPress sites on one `t3.small` behind an ALB, with RDS and EFS) to ECS on EC2. Most of the work happens outside this repository, in `abd-cloud`, `abd-cloud-packer` and a new container images repository, under separate work packages WP-01 to WP-07. This brief carries the Tulox side only. Tulox moves last, after the WordPress sites have proven the pattern.

## Decisions

- ECS on EC2 replaces the bare EC2 host and the SSM push deploy. EKS was rejected on control plane cost, and Fargate on per-task cost (roughly $80 to $100 a month for about eleven tasks against one RI-covered instance). Fargate is to be revisited when the reserved instance expires.
- The existing single ALB stays. Each site moves by repointing its host-header listener rule to a new ECS target group, optionally weighted first. There is no DNS flip and no second ALB.
- Tulox images build on a shared Analysis by Design layer chain (base, then PHP, then Laravel) held in a new images repository. Debian slim is used, because Alpine was rejected for PHP over musl performance issues. Images are multi-arch: production is amd64 (`t3`), while both Macs are arm64.
- Queues move to SQS with long polling. Valkey runs as a container pinned to the on-demand host for cache, sessions, scheduler locks and Reverb scaling, until ElastiCache is justified. This keeps the earlier Valkey decision; only its hosting changes.
- Containers are replaced nightly around 04:00, gated on a smoke test, with the ECS deployment circuit breaker rolling back failed deployments. Hosts are refreshed weekly, launching before terminating. Daily replacement is chosen deliberately, to prove the scaling and recovery path continuously.
- Spot is used for burst capacity only, above an RI-covered on-demand base of one. Valkey, the scheduler and at least one web task stay on on-demand. Friday and Saturday evening scale-out is scheduled, with target tracking as a backstop.
- Local development mirrors production: the same images under Compose on the laptop (Docker Desktop) and the Mac mini (Colima), with a dev override for bind mounts and hot reload. `make dev` remains the entry point. The mflux image workers on the mini stay native.
- The NAT gateway is replaced first by a self-healing fck-nat instance using route-flip replacement, which funds the migration overlap. That work lives in `abd-cloud`, not here.
- Every work package runs Discovery (read-only), then Clarify (stop for Dave's rulings on structure), then Build. Agents never decide module structure, naming or layout by default.

## Item 1: Tulox Containerisation and Move to ECS

**Type**: work-package
**Slug**: container-platform-migration

### Why this exists

Tulox currently deploys by GitHub Actions and SSM push to a single EC2 host shared with the WordPress sites, using `tulox-init.sh` and `tulox-deploy.sh` from `abd-cloud-packer`, with manual rollback to a `last-known-good` tag. The estate is moving to ECS on EC2 so each site runs in its own containers, capacity can burst on spot for busy evenings, and every deploy and recovery path is exercised nightly. Tulox moves last, once the WordPress sites have proven the cluster, the ALB rule cutover and the nightly rollout.

### Dependencies

Infrastructure work packages outside this repository must land first:

- WP-01 (NAT instance and S3 gateway endpoint).
- WP-02 (codified ECR and GitHub OIDC push role for this repository).
- WP-03 (the `abd-laravel` base image).
- WP-04 (the ECS cluster and service pattern).
- WP-05 (the WordPress sites moved).

`wp-000a-marketing-screenshot-asset-pipeline` places its S3 sync-down step in `tulox-deploy.sh` and `tulox-init.sh`, both of which this package retires. Whichever lands second must move that step: to a container entrypoint, an init container, or the CI deploy step. State this dependency in both documents.

### Process

Three phases, as for every package in the programme.

1. **Discovery** (read-only): change nothing except writing the discovery report.
2. **Clarify**: present the questions with options and a recommendation, then stop for Dave's rulings, recorded in this document.
3. **Build**: only after the rulings.

### Discovery

1. Every long-running process Tulox needs in production: PHP-FPM, queue workers (which queues, and the connection), the scheduler, Reverb, and anything else run by systemd or cron on the current host.
2. Queue usage: any job delayed beyond 15 minutes (the SQS maximum), the longest job timeout, Horizon usage (Horizon is Redis-only and is lost with SQS), and batches or chains that depend on driver features.
3. Cache, session, lock and broadcast drivers, and any reliance on the local filesystem other than the EFS-backed `storage/app`.
4. The EFS layout: the `storage/app` symlink to `/mnt/efs/tulox.uk/storage`, the disks rooted under it (`branding`, `menu_images`, `library_images`, `hierarchy_maps`, `marketing_images`), and the ownership the web user needs.
5. Configuration and secrets: how `.env` reaches the host today, and what lives in Secrets Manager (including the Stripe secrets).
6. Everything `tulox-init.sh` and `tulox-deploy.sh` do: migrations, cache warming, `storage:link`, the asset sync, release tagging, and health checks.
7. The local development setup: the Makefile, the existing Compose files, Colima specifics on the mini, and how the mflux workers reach the app.
8. ADR 0013 (`docs/decisions/0013-infrastructure-and-deployment.md`): the sections this package supersedes.
9. The PHP extensions the application needs beyond `abd-laravel`.

### Clarify (minimum questions)

- **Process layout**: one image with role-specific commands (web, worker, scheduler, Reverb) as separate ECS services (recommended), or fewer combined services.
- **Migrations**: run as a one-off ECS task before the service update in CI, or in the web entrypoint behind a lock. A one-off task is recommended, so concurrent tasks never race.
- **Scheduler**: a single dedicated service with one task, or `onOneServer()` on every task backed by Valkey.
- **Reverb behind the ALB**: its listener rule, its health check, and whether the existing WebSocket path needs stickiness.
- **SQS queues**: one per Laravel queue name or shared, the visibility timeout (above the longest job timeout), and a dead-letter queue with a `maxReceiveCount`.
- **Local SQS stand-in**: ElasticMQ (lighter) or LocalStack.
- **Rollback model**: the previous image tag through the circuit breaker plus a manual "redeploy tag X" workflow, replacing `last-known-good`.
- **Where the task definitions live**: in this repository or in `abd-cloud`. This follows the WP-04 ruling; restate it here.
- **Release cadence**: whether the nightly 04:00 rollout applies to Tulox (rebuilding on the latest `abd-laravel` with no code change), or Tulox deploys only on release-please releases plus a nightly base-image rebuild.

### Scope

1. A Dockerfile on `abd-laravel`, built multi-arch in CI on release and pushed to ECR through OIDC.
2. Compose for local development: production-shaped services (web, worker, scheduler, Reverb, Valkey, MySQL, an SQS stand-in) plus a dev override for bind mounts and hot reload. `make dev` works unchanged on the laptop and the mini.
3. The queue connection switched to SQS in production, with long polling (`ReceiveMessageWaitTimeSeconds=20`), and tests covering any job affected by the 15-minute delay cap.
4. ECS service definitions per the WP-04 pattern and the rulings above, with health checks, hard memory limits, and placement constraints keeping Valkey, the scheduler and one web task on on-demand.
5. The CI deploy: build, push, run the migration task, update the services, and wait for steady state. The circuit breaker handles rollback.
6. Cutover: a weighted ALB rule to the new target group, verified end to end (ordering, Stripe webhooks, printing, Reverb), then 100%. Rollback means repointing the rule. Cut over at a quiet time, never on a Friday or Saturday evening.
7. **ADR 0013 amendment**, recording the move from SSM push to ECS rolling deployments, image tag rollback in place of `last-known-good`, the new topology, SQS and Valkey hosting, and nightly replacement. Write it as a dated amendment within the existing ADR. Discovery confirms the anchor section in the current file before placement.
8. Runbook updates for deploy, rollback, scaling, and local setup.

### Out of scope

- The cluster, ASGs, ECR, NAT and ALB plumbing (infrastructure work packages).
- Moving image generation to AWS Batch; that is separate and unaffected.
- The dedicated Tulox AWS account; this package should make it easier, not do it.

### Open questions

- Whether the Valkey container needs persistence (an AOF on EFS) once queues are on SQS, or whether losing it on a host replacement is acceptable for cache, sessions and locks. Sessions are the case to check: a lost session logs out admin users and kiosk sessions.
- The connection budget on RDS once worker and web tasks scale out on spot (tasks times `pm.max_children`, plus queue workers).

### Done when

- Tulox runs entirely on ECS, with the old host serving no Tulox traffic.
- A release deploys through CI with no SSH or SSM steps, and a deliberately failing release rolls back automatically.
- Tulox survives a weekly host refresh and a spot burst scale-out and scale-in with no failed orders.
- `make dev` brings up the production-shaped stack on both Macs.
- ADR 0013 carries the dated amendment.
