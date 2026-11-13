# Container platform: architecture

Status as of 2026-11-13. For the working guide (how the pieces fit, and how to do the everyday jobs), see [ecs-primer.md](ecs-primer.md). The decisions behind all of this are the rulings in [docs/work-packages](work-packages/).

## Summary

**What it is.** The Analysis by Design web estate (the WordPress sites, and later Tulox and mortgage.daverix.ai) is moving off one hand-built server onto a container platform on AWS (ECS on EC2). Each site becomes its own container image, built and tested automatically every night, and run as its own service. The old server stays up, untouched, until the last site has moved, so any site can go back to it by reverting one change.

**Why.** On the old server every site shared one machine image that updated WordPress, plugins and themes from manifests at boot. Updates raced on shared storage, the running sites drifted from anything tested, and one bad update could take several sites down together. In the new model the code in a running site never changes: updates arrive only as a new, smoke-tested image, and a failed one never replaces the working one.

**What it costs.** No new recurring spend above roughly £5 a month without a ruling. The container hosts are covered by two 3-year regional `t4g` reserved instances (to 2029-08-02 and 2029-11-11). The NAT gateway was replaced by a `t4g.nano` NAT instance (about $3.36 a month). The two servers overlap only while sites move.

**Risk and control.** Every site moves on its own, first to a preview address against the live database, then by adding its real domain to its listener rule. Nothing changes in DNS, and rollback is a revert, an apply and a deploy. Failed deployments roll themselves back (ECS circuit breaker), and failures email the `abd-alerts` topic as readable text.

| Area | Status |
|---|---|
| WP-01: NAT instance and S3 endpoint | Complete, 2026-11-11. NAT gateway removed |
| WP-02: ECR and CI access | Complete, 2026-11-11 |
| WP-03: container base images | Complete, 2026-11-11 |
| WP-04: ECS cluster, hosts, deploy pipeline, mail relay | Complete, 2026-11-13. Spot capacity deferred (ruling 23) |
| WP-05: WordPress sites onto ECS | Under way |
| blacklit.uk | Live on ECS (pilot) |
| daverix.ai, analysisbydesign.co.uk | Previews live; cutover in abd-cloud-params#46 |
| amyegillin.uk | Image fails its smoke test (akismet activation with the pipdig theme); service not yet applied |
| baltihot.co.uk | Old host; serves customers, so Dave tests it himself before it moves |
| oranjj.uk | Old host, for now |
| daverix.uk | Old host, redirecting to daverix.ai; the ALB redirect (WP-05 ruling 10) is not built |
| Tulox, mortgage.daverix.ai | Later package |
| Retiring the old host (step 7) | After the last site and Tulox |

---

## Senior engineer view

### Shape

```text
Internet
  -> ALB abd-wordpress-ec2-asg (existing, the only one)
       HTTPS listener: host-header rules per service, priorities 100s WordPress,
       200s Tulox, 900s tests; default action -> old host (abd-wordpress-ec2-asg ASG)
       -> target group per service (bridge mode, dynamic host ports)
            -> ECS cluster abd-wordpress-cluster
                 capacity provider: ASG abd-wordpress-ecs-hosts, t4g.small x2 (min 2, max 3),
                 ECS-optimised AL2023 arm64, private app subnets
                 services: one per site (abd/wp-<site>), smtp relay (awsvpc), hello (test)
Private subnets egress -> fck-nat t4g.nano, ASG of one, route flip on replacement
                       -> S3 gateway endpoint (S3 and ECR layers)
Shared: RDS MySQL 8.4 (db.wordpress), EFS abd-wordpress-html (uploads only), SSM, ECR
CI: GitHub Actions (OIDC) -> ECR; nightly rebuild; 04:00 London rollout
```

Everything is eu-west-1 in the `abd-wordpress` account (800653036500), built by Terraform templates here with config in `abd-cloud-params`.

### Network and egress (WP-01)

- One NAT instance (fck-nat, `t4g.nano`) in an ASG of one, with an auto-assigned public IP. A replacement boots, flips the three private route tables to itself, then completes its launch lifecycle hook; the old one drains. Planned refreshes showed no egress loss. Weekly refresh, Tuesdays 04:00 London. Runbook: [runbooks/nat-instance.md](runbooks/nat-instance.md).
- The private default routes are owned by the NAT instance, not Terraform (ruling 5); rollback is the runbook's "Rollback after teardown", not a flag flip.
- S3 gateway endpoint only; no interface endpoints (cost guardrail).

### Compute (WP-04)

- Cluster `abd-wordpress-cluster` (`app.ecs`, [compute/ecs-cluster](../tf-templates/compute/ecs-cluster/)), with managed scaling, managed termination protection and managed draining on its capacity provider.
- Hosts `abd-wordpress-ecs-hosts` (`ecs.hosts`, `compute/ec2-asg`), AMI resolved from SSM at each launch, so the weekly refresh (Wednesdays 03:00 London, launch before terminate, 100/110) is also the patching. Apply order: cluster, hosts, cluster again.
- Bridge networking with dynamic host ports. `awsvpc` only where a task needs its own DNS name (the relay, later Valkey); a `t4g.small` has 3 ENIs and no trunking, so at most 2 awsvpc tasks per host.
- No Container Insights (ruling 11), behind a variable.

### Services ([compute/ecs-service](../tf-templates/compute/ecs-service/))

One template, one params target per service (`wordpress-vpc/svc.<name>`). Each service gets:

- Task family `abd-wordpress-<name>`, ARM64; log group `/ecs/abd-wordpress/<name>`, 14 days.
- Execution role scoped to its own SSM parameters and log group; task role with mount rights through its own EFS access points only.
- Circuit breaker with rollback, 100/200 launch before stop.
- Optional: target group and host-header rule, alias records under `abd-wp.uk`, a no-healthy-targets alarm, EFS access points (owned by 10001), tmpfs mounts, EventBridge Scheduler tasks (WP-Cron every 5 minutes), awsvpc with a Cloud Map record.

**Deployment ownership** (WP-04 ruling 6): Terraform creates the service and the task definition's shape, then ignores `task_definition`. CI takes the family's latest ACTIVE revision, swaps the one container's image for a digest, registers it and updates the service. A Terraform change to the task definition therefore goes live at the next deploy, not at apply.

### WordPress sites (WP-05)

- Image `abd/wp-<site>` = `abd/wordpress` (pinned core, WP-CLI, common plugins) plus the site's manifest, installed at build time at the current stable wordpress.org release. Premium zips come from `s3://abd-wordpress-html/premium/<name>/<version>.zip`. `DISALLOW_FILE_MODS` is on; nothing updates inside a running container.
- One container: nginx and PHP-FPM under s6-overlay, non-root (10001), port 8080, `/healthz`, logs to stdout. FPM `ondemand`, 10 children; memory reservation 256 MiB, limit 768 MiB.
- Writable paths: `uploads` and `w3tc-config` on EFS (access points `/ecs/<domain>/...`), W3TC's page cache on tmpfs.
- Configuration: non-secret settings in the service's tfvars `environment`; 11 secrets per site as SSM SecureStrings `/abd-wordpress/<domain>/<VARIABLE>`, injected as ECS `secrets`. Values never reach Terraform state, Git or an image.
- WP-Cron: `DISABLE_WP_CRON`, plus a scheduled task running `wp cron event run --due-now`.
- Mail: WP Mail SMTP straight to IONOS, as before. Anything else uses the relay, `smtp.abd-wordpress.internal:25`, which rewrites `From:` to `abd-cloud@analysisbydesign.co.uk`.

### Images and supply chain (WP-02, WP-03)

- Chain in `abd-cloud-containers`: `debian:trixie-slim` (by digest) -> `abd/base` -> `abd/php` (8.3, 8.5) -> `abd/wordpress` / `abd/laravel` -> `abd/wp-<site>`; `abd/postfix` on `abd/base`. `linux/arm64` only.
- Tags: floating (`8.3`) plus immutable dated (`8.3-2026.11.13`); deployments pin the digest. Built with `--provenance=false` so tags point at plain manifests and the untagged-image expiry cannot remove a live image.
- ECR: `MUTABLE` tags, scan on push, untagged expire after 7 days, newest 30 dated images kept. Official images through the `ecr-public` pull-through cache.
- CI reaches AWS only through GitHub OIDC. The push role (`abd/*`, plus read on the premium prefix) and the deploy role (named services only) trust `refs/heads/main` only, using GitHub's immutable subject form.

### Delivery

```text
02:00 UTC   build.yml     base chain, smoke tests, push (no layer cache on Sundays)
after that  sites.yml     every site, no cache, smoke test, push
04:00 LON   rollout.yml   floating tag -> digest per enabled service; deploy.yml where it differs
on merge    build.yml / sites.yml -> deploy straight away (WP-04 ruling 7)
```

- `deploy.yml` waits up to 20 minutes for the PRIMARY deployment to reach COMPLETED, and fails on a rollback. Runs per service queue rather than cancel.
- Services join the rollout through a repository variable: `SMTP_DEPLOY=true` for the relay; `SITES_DEPLOY` (a list of domains) for the sites, added by abd-cloud-containers#15, which is open. Until it merges, site deploys are manual runs of `deploy.yml`.
- Jobs run on the Mac mini runner while its heartbeat is fresh, otherwise on GitHub-hosted arm64 runners.

### Routing and cutover (WP-05 ruling 27)

- A new service starts with only its preview hostname, `<service>.abd-wp.uk` (the ALB's `*.abd-wp.uk` certificate), and `WP_HOME` set to it, against the live database.
- Cutover is one params PR: `WP_HOME` and `WP_SITEURL` to the real domain, and the domain and its www added to `hostnames`. Apply, then deploy so the new revision runs. The domain's DNS and certificate stay in `hosted-sites`, and the ALB's default action still points at the old host, so rollback is the reverse PR.
- Uploads are copied into the new access point directories with `wp-efs-sync.sh` before cutover; the old tree is only read.

### Observability

- Logs: CloudWatch, `/ecs/abd-wordpress/<service>`, stream prefix the container name.
- Alerts to SNS `abd-alerts` (email), as formatted text: `deployment-failed`, `service-error`, `task-not-started`, `task-exited` (non-zero exit only), and each service's no-healthy-targets alarm. NAT instance alarms as in the runbook.

### Trade-offs recorded

- ECS on EC2 over Fargate (per-task cost) and EKS (control plane cost); revisit Fargate when the RIs end.
- One ALB, not two: cutover by listener rule, no DNS change. At step 7 a new ALB replaces the one owned by the old host's `app.wordpress` target (WP-04 notes).
- SSM Parameter Store over Secrets Manager: standard parameters are free.
- Spot only for burst, and deferred until WP-05 has measured load.

### Known gaps

- No alert on a failed instance refresh (WP-01 follow-up). Check the Tuesday and Wednesday refreshes until one exists.
- The `abd-tf-state` bucket is not versioned.
- The site smoke test discards WP-CLI's output, so a failed activation does not say why.
- Retiring the old host, its AMI pipeline and the old ALB is step 7 of the [programme](work-packages/00-programme-overview.md).

### Further reading

| | |
|---|---|
| Programme, settled decisions, protocol | [00-programme-overview.md](work-packages/00-programme-overview.md) |
| Rulings and status per package | [WP-01](work-packages/wp-01-nat-instance-and-s3-endpoint.md), [WP-02](work-packages/wp-02-ecr-and-ci-access.md), [WP-04](work-packages/wp-04-ecs-cluster-and-capacity.md), [WP-05](work-packages/wp-05-wordpress-containerisation.md); WP-03 in `abd-cloud-containers` |
| Templates | [ecs-cluster](../tf-templates/compute/ecs-cluster/), [ecs-service](../tf-templates/compute/ecs-service/), [ec2-asg](../tf-templates/compute/ec2-asg/) |
| Images, CI and deploy | `abd-cloud-containers` `README.md` and `images/wordpress-site/README.md` |
