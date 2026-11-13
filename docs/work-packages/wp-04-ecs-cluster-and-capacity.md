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

## Rulings

Recorded 2026-11-11, against the questions in `docs/discovery/wp-04.md`. Answered in batches; questions without a ruling are still open.

1. **Cluster and hosts layout**:
   - The cluster grows `compute/ecs-cluster` and reuses the `app.ecs` target (empty state), so it is named `abd-wordpress-cluster`. `prevent` is removed from its `sequence/prod.csv` row.
   - The hosts are a new params target, `wordpress-vpc/ecs.hosts`, on `compute/ec2-asg` with `enable_load_balancer = false` and `name = "ecs-hosts"`, so the ASG is `abd-wordpress-ecs-hosts`.
   - The cluster template owns the capacity providers and the cluster's provider association and default strategy, finding each host ASG by name. Sequence: the cluster first, then the hosts, then a second cluster apply whenever a host ASG is added.
2. **Modules**: extend `asg`, `launch-template`, `ecs/cluster`, `ecs/service`, `ecs/task` and `monitoring/cloudwatch/group`, each backward compatible. Retire the `ecs-fargate` template and its empty 2019 state file.
3. **Host AMI**: the ECS-optimised AL2023 arm64 AMI through `resolve:ssm:` in the launch template, resolved at each launch. The hosts are a **new ASG** (ruling 1), separate from the current `abd-wordpress-ec2-asg`, which keeps serving the sites untouched until each one moves.
4. **Host size**: `t4g.small` for WP-04 (accepted above the £5 guardrail for the overlap). For WP-05, two `t4g.small` (which the regional RI fully covers once the old host is retired) may be preferred to one `t4g.medium` if the measured memory footprint allows; decided in WP-05.
   - **Second reserved instance**: bought 2026-11-12, matching the first (`t4g.medium`, regional eu-west-1, standard, Linux/UNIX, default tenancy, No Upfront, 3 years, in `abd-wordpress`): `32996921-20f3-45fc-98db-a65eb2ee13ee`, ending 2029-11-11. The first is `bf12a06f-5b4c-4a60-9206-15a6b4f97b98`, ending 2029-08-02. Being size-flexible, the two RIs cover 4 t4g units (nano 0.25, small 1, medium 2). Until `ecs.hosts` is applied, the new RI only covers the NAT nano.
   - **Target layout for WP-05**: the ECS hosts use all 4 units, either four `t4g.small` or two `t4g.small` plus one `t4g.medium` for the larger sites, running the sites and the small pinned tasks (smtp relay, cron, later Valkey). Either gives ECS well over the estimated 3.0 GiB of task reservations, with room for rolling deployments and the loss of a host. The NAT `t4g.nano` stays outside the RIs, on demand (about $3.36 a month), which is accepted: the NAT gateway it replaced cost far more. Chosen in WP-05 from measured task sizes; WP-04 stays at min 1, max 2.
   - **Pricing basis** (eu-west-1, Linux, per month): `t4g.medium` RI $11.61 (3-year No Upfront) against $26.86 on demand; `t4g.small` $13.43 and `t4g.nano` $3.36 on demand. During the overlap (old medium, ECS small and NAT nano) the second RI saves about $5.18 a month. After WP-05, four smalls cost $23.22 a month on the two RIs, against $38.47 with one RI (a saving of about $15.25 a month) or $53.72 all on demand. A 1-year term ($16.94) saves almost nothing, so 3 years. It runs to 2029-11-11, three months past the first RI; a standard RI cannot change family, so this commits the hosts to t4g until then.
5. **Service structure**: one reusable template, `tf-templates/compute/ecs-service`, with one params target per service (`wordpress-vpc/svc.<name>`). Terraform owns the target group, listener rule, service, log group, task role and the task definition's shape.
6. **Deployment ownership**: Terraform registers the task definition but ignores `task_definition` on the service. CI takes the family's latest revision, swaps only the image digest, registers it and updates the service.
7. **Rollouts**: each image repository calls a reusable rollout workflow kept in `abd-cloud-containers`. A merge to `main` deploys **immediately** after its build and smoke test; only the nightly rebuilds are rolled out at 04:00. CI gets a deploy role through a new `ecs_deploy_roles` map in `security/github-deploy`.
8. **Valkey**: one task in `awsvpc` mode with a Cloud Map private DNS A record. Built in the Tulox package; WP-04 makes the network mode configurable per task.
9. **Secrets**: ECS `secrets` from SSM Parameter Store, with each service's execution permissions scoped to its own prefix.
10. **Logs**: one log group per service, `/ecs/abd-wordpress/<service>`, kept 14 days.
11. **Monitoring**: no Container Insights for now, behind a variable so it can be switched on later. Alarms on each service target group's `HealthyHostCount`, plus an EventBridge rule sending ECS deployment-failure and task-stopped events to `abd-alerts`.
12. **Test hostname and priorities**: `hello.abd-wp.uk` on the existing `*.abd-wp.uk` certificate. Listener rule priorities are explicit per service, in bands (100s WordPress, 200s Tulox, 900s tests).
13. **Weekly host refresh**: Wednesdays at 03:00 (Europe/London), with managed scaling, managed termination protection and managed draining, `scale_in_protected_instances = Refresh`, and launch before terminate (100/110).

14. **Mail relay**: a small postfix relay service on ECS, reached by a Cloud Map private DNS name, for anything without its own SMTP settings (the system, cron, any app pointed at a local relay). The IONOS relay login stays in one SSM parameter. WordPress sites keep sending straight to IONOS through WP Mail SMTP. This brings the Cloud Map namespace (ruling 8's pattern) forward into WP-04.
15. **Postfix image**: built in `abd-cloud-containers` as `images/postfix/` on `abd/base`, pushed as `abd/postfix` (one new entry in the registry params). Layout within that repository is Dave's call, per its working agreement.
16. **Cloud Map namespace**: private DNS namespace `abd-wordpress.internal`, so the relay is `smtp.abd-wordpress.internal` and Valkey later `valkey.abd-wordpress.internal`.
17. **Postfix layout**: `images/postfix/` holds `Dockerfile`, `README.md`, `test.sh`, its own complete `rootfs/etc/postfix/main.cf` (none of Debian's defaults kept) and the entrypoint `rootfs/usr/local/bin/abd-postfix`, which sets `relayhost`, `mynetworks` and `myhostname` at start (Dave, 2026-11-12).
18. **Postfix tags**: `trixie` and `trixie-<yyyy.mm.dd>`, as `abd/base`. Built with the existing `make build IMAGE=postfix` and `make test IMAGE=postfix`, and included in `build-all` and `test-all` (Dave, 2026-11-12).
19. **Deploy gate**: a `deploy-smtp` job in `build.yml` rolls a merge to `main` out through `deploy.yml`, behind the repository variable `SMTP_DEPLOY`, set to `true` once `svc.smtp` is applied (Dave, 2026-11-12).
20. **Nightly rollout**: a new `rollout.yml` in `abd-cloud-containers`, scheduled at 03:00 and 04:00 UTC and gated on London's offset so it runs at 04:00 London. For each enabled service it resolves the floating tag's digest and calls `deploy.yml` only where the running image differs. The WordPress sites join it under WP-05 ruling 21 (Dave, 2026-11-12).
21. **Two hosts at all times**: `abd-wordpress-ecs-hosts` runs min 2, max 3 `t4g.small`. With the second RI bought, the two regional t4g RIs (4 units) already pay for the old host's `t4g.medium` (2) and two smalls (2), so a single small leaves an RI unit unused. ECS managed scaling may go to a third host for a refresh or a short burst, on demand. This replaces "WP-04 stays at min 1, max 2" in ruling 4; the WP-05 layout once the old host retires is still decided there (Dave, 2026-11-13).
22. **Relay senders**: the envelope sender of everything the relay sends is its IONOS login, a dedicated no-reply mailbox, from the `sasl_passwd` parameter. Every `From:` header is replaced with the platform the mail comes from, `"abd-cloud" <abd-cloud@analysisbydesign.co.uk>`, set by the service's `MAIL_FROM` (required) and `MAIL_FROM_NAME` (optional). Tested from a local container through IONOS on 2026-11-13: accepted and delivered as `abd-cloud@` (Dave, 2026-11-13).
23. **Spot capacity deferred**: scope item 9 (the spot ASG and capacity provider, critical tasks pinned to on-demand, and the Friday and Saturday evening scaling) waits until WP-05 has measured real load. The two on-demand hosts are already paid for by the RIs (ruling 21), so spot would only save on burst capacity above them, and sizing it now would be guesswork. WP-04 closes without it (Dave, 2026-11-13).

Notes from the same session:
- **ALB**: keep the existing ALB and add listener rules and target groups to it; running two is ruled out on cost. The existing ALB belongs to the old host's `app.wordpress` target, so it would be destroyed with it. At transition (step 7) a new ALB, under the new naming, is enabled in the `ecs.hosts` build while the old one still runs; state manipulation lets the new one build alongside, and every listener rule, certificate and DNS record moves across to it. The old ALB is then taken out of the `app.wordpress` state (or otherwise detached by state manipulation) before that target is destroyed. Two ALBs run only for the changeover; a short outage is acceptable. The `alb` module's built-in target group registers the ASG's instances on port 80, so it will need to become optional (or the default action a fixed response) before ECS hosts can own the ALB. `hosted-sites` finds the ALB by name (`trg_lb_name`), so it can be repointed by a variable.
- **First move (WP-05)**: one quiet site first, built and tested, then traffic repointed by its listener rule (or DNS).
- **Mail, cron and mortgage.daverix.ai** need building. Mail is needed early, because sites deliver mail over SMTP.
- The reboot bug on the current host is not worth fixing; it goes away with the move to ECS.

## Status

**Complete on 2026-11-13.** Done when met on 2026-11-12; the mail relay live on 2026-11-13. The spot capacity (scope item 9) is deferred to after WP-05 (ruling 23). The first scheduled refresh with two hosts (2026-11-18, 03:00) runs unattended; if it fails, it is fixed then, outside this package (Dave, 2026-11-13).

Merged and applied:
- abd-cloud-modules #33: the six modules extended for ECS. Every existing caller (`abd-global`, `abd-wordpress`, `app.wordpress`, `nat-instance`) planned with no changes.
- abd-cloud #71 and abd-cloud-params #34: the cluster `abd-wordpress-cluster` (`app.ecs`) with its capacity provider, the `abd-wordpress.internal` namespace and the EventBridge rule to `abd-alerts`; the hosts `abd-wordpress-ecs-hosts` (`ecs.hosts`, `t4g.small`, ECS-optimised AL2023 arm64) with the Wednesday 03:00 refresh. The ECS alert rule passed 7 of 7 test events.
- abd-cloud #73 and abd-cloud-params #36: the `compute/ecs-service` template, the `svc.hello` target and the `github-ecs-deploy-abd-cloud-containers` role (`security/github-deploy`, `ecs_deploy_roles`).
- abd-cloud-containers #7: the reusable rollout workflow `deploy.yml`, with repository variable `ECS_DEPLOY_ROLE_ARN`.

Verified:
- **hello on the existing ALB**: `https://hello.abd-wp.uk` returns 200 through listener priority 900. The task runs in bridge mode on a dynamic host port, its image comes through the `ecr-public` pull-through cache, and its EFS access point mounts with TLS. The target is healthy and the `HealthyHostCount` alarm is OK.
- **Rollout** (run 43141566890): `nginx:mainline-alpine` registered as `abd-wordpress-hello:2` and completed in about 2.5 minutes. A request loop saw 286 requests, all 200, with the server moving from nginx 1.30.6 to 1.31.1.
- **Broken deployments**: runs 43141679111 (`nginx:mainline-alpin`, a typo) and 43142285458 (`nginx:does-not-exist`) each registered a revision whose tasks failed with `CannotPullImageManifestError`. After 3 failed tasks the circuit breaker rolled the service back to `:2`, and the workflow failed with "rolled back". Revision `:2` kept serving throughout, and the runs queued behind each other rather than cancelling.
- **Instance refresh**: started with the scheduler target's own input (100/110, warmup 120, `ScaleInProtectedInstances = Refresh`). The new host launched, ECS drained the old one and started hello on the new host before stopping the old task, and the refresh finished in 6.5 minutes. A request loop saw 367 requests, all 200.

Found while testing:
- A new service's `HealthyHostCount` alarm goes to ALARM for a few minutes after creation, because the metric has no data yet and missing data counts as breaching. That sends one alert to `abd-alerts` per new service. Accepted: counting missing data as breaching is what catches a target group with no targets.
- During the refresh, ECS managed scaling raised the hosts to 2 to place hello while the old host drained, and the refresh then kept both. Managed scaling scales the empty host back in once it has been idle for about 15 minutes.
- A `t4g.small` host has 3 network interfaces and ENI trunking is not available, so each host runs at most 2 awsvpc tasks (the relay, and later Valkey).

Mail relay (rulings 14 to 16, 22), live:
- abd-cloud-params #39, #40: the `abd/postfix` repository and the `svc.smtp` target (awsvpc, `smtp.abd-wordpress.internal:25`, inbound from the private app subnets only, `SASL_PASSWD` from `/abd-wordpress/shared/postfix/sasl_passwd`, `MAIL_FROM` per ruling 22), and `smtp` added to the deploy role. abd-cloud #77: `svc.smtp` in the plan and drift workflows.
- abd-cloud-containers #11: the `abd/postfix` image (rulings 17 to 20), with `deploy-smtp` gated on `SMTP_DEPLOY=true`.
- Verified 2026-11-13: `smtp` runs one HEALTHY task (`abd-wordpress-smtp:4`), registered in Cloud Map as `smtp.abd-wordpress.internal`; postfix 3.10.13 started with the relay host from the secret, which stays out of the logs. Ruling 22's sender rewriting was tested through IONOS from a local container.
- The first rollout failed: the image needs `MAIL_FROM`, which the first `svc.smtp` apply lacked, so the circuit breaker stopped it after 3 tasks. The failed revision already held the new digest, so `rollout.yml` then counted `smtp` as up to date; abd-cloud-containers #13 makes a service up to date only when its primary deployment is also COMPLETED.
- The `postfix status` health check logged a "mail system is running" line every 30 seconds. abd-cloud-params #43 replaced it with the same test, silently (`kill -0` on the master's PID file), rolled out as `abd-wordpress-smtp:8` on 2026-11-13.

Hosts: ruling 21 raised `abd-wordpress-ecs-hosts` to min 2, max 3 (abd-cloud-params #42), applied 2026-11-13: `i-01438166b6c962a22` (eu-west-1a) and `i-0e56b8a8c8587a930` (eu-west-1b), both ACTIVE in the cluster. The first scheduled refresh with two hosts is on 2026-11-18 at 03:00.

For later packages:
- WP-05: each site is a `svc.<site>` target on `compute/ecs-service`, added to `ecs_deploy_roles` `services`, with listener priorities in the 100s. Sites without their own SMTP settings can use `smtp.abd-wordpress.internal:25`.
- The Tulox package: Valkey as an awsvpc service with `service_discovery_namespace = "abd-wordpress.internal"`, so it is `valkey.abd-wordpress.internal`; listener priorities in the 200s.
- The ALB transition follows the notes above. The spot capacity (scope item 9) is picked up after WP-05 has measured load (ruling 23).
