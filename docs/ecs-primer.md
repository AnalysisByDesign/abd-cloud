# ECS primer

A working guide to the container platform for someone comfortable with Linux, Docker, Git and Terraform but not with ECS, and a refresher after time away. The design and its reasons are in [architecture.md](architecture.md); the decisions are the rulings in [docs/work-packages](work-packages/).

## ECS in ten terms

| Term | What it is here |
|---|---|
| **Cluster** | `abd-wordpress-cluster`: a name that hosts join and services run in. Costs nothing on its own |
| **Container instance** (host) | An EC2 instance running the ECS agent. Ours are `abd-wordpress-ecs-hosts`, two `t4g.small` (min 2, max 3) |
| **Capacity provider** | Links the cluster to the hosts' ASG, so ECS adds a host when tasks do not fit and drains one before it goes |
| **Task definition** | The `docker run` recipe: image, memory, environment, secrets, mounts, health check, log settings. Each change is a new numbered **revision** (`abd-wordpress-blacklit-uk:7`); old revisions stay, so you can go back |
| **Task** | One running copy of a task definition (one or more containers on one host) |
| **Service** | Keeps N tasks of a revision running, replaces failed ones, and registers them with a target group. One per site, named after the domain with dots as dashes (`blacklit-uk`) |
| **Deployment** | A service moving from one revision to another. New tasks start first, the old ones stop once the new are healthy. The **circuit breaker** rolls back if new tasks keep failing |
| **Target group and listener rule** | The ALB side. A listener rule matches host names and forwards to the service's target group; ECS registers each task's dynamic host port there |
| **Execution role / task role** | Execution role: what ECS needs to start the task (pull the image, read its secrets, write logs). Task role: what the code inside may do in AWS (here, only mount its EFS access points) |
| **EFS access point** | A directory on the shared file system presented as the root of a mount, with fixed ownership. Each site sees only its own `uploads` and `w3tc-config` |

## Where things live

| Repository | Holds | You change it to |
|---|---|---|
| `abd-cloud` (here) | Terraform templates, `tf-run.sh`, work packages, these docs | Change how a kind of resource is built (all services share `compute/ecs-service`) |
| `abd-cloud-params` | One folder per deployed thing: `*_config.sh` (which template, which state file) and `*.tfvars` (the values) | Add or change one service, host group or repository |
| `abd-cloud-modules` | Child modules the templates call | Rarely; changes must plan with no diff for existing callers |
| `abd-cloud-containers` | Dockerfiles, site manifests (`sites/<domain>/`), CI workflows, operator scripts (`images/wordpress-site/bin/`) | Change what is in an image, add a site, change how builds and deploys run |

Useful params paths, all under `abd-cloud-params/abd-wordpress/`:

| Path | What |
|---|---|
| `wordpress-vpc/app.ecs` | The cluster, its alerts and the Cloud Map namespace |
| `wordpress-vpc/ecs.hosts` | The host ASG |
| `wordpress-vpc/svc.<service>` | One service each: `blacklit-uk`, `daverix-ai`, `smtp`, `hello` and the rest |
| `wordpress-vpc/hosted-sites` | Each real domain's DNS and certificate (unchanged by the move) |
| `wordpress-vpc/app.wordpress` | The old host and the ALB it owns |
| `wordpress-vpc/nat-instance` | The NAT instance |
| `account-global/container-registry` | ECR repositories, one per image (`abd/wp-<service>`) |
| `account-global/github-deploy` | CI roles: ECR push, and the ECS deploy role's list of services |

## A request's journey

```text
browser -> DNS (hosted-sites) -> ALB abd-wordpress-ec2-asg, HTTPS ends here
  -> listener rule: host blacklit.uk? -> target group abd-wordpress-blacklit-uk
       -> host:dynamic port -> container port 8080 -> nginx -> PHP-FPM -> WordPress
            -> RDS MySQL (mysql-rw.int.wp.abd-wp.uk), EFS for uploads
  no rule matches -> default action -> old host
```

## A change's journey

```text
merge to main in abd-cloud-containers
  -> build.yml (base chain) -> sites.yml: build abd/wp-<site>, smoke test, push to ECR
  -> deploy.yml: latest revision + new image digest -> new revision -> service update
  -> ECS starts the new task, ALB health check passes on /healthz, old task stops
  failure at any step: nothing changes, or the circuit breaker puts the old revision back
```

The nightly run is the same without the merge: every image rebuilt at 02:00 UTC, every site after it, and the 04:00 London rollout deploys whatever changed.

## The clock

| When (London unless stated) | What |
|---|---|
| Nightly 02:00 UTC | `build.yml` rebuilds the base images (no layer cache on Sundays), then `sites.yml` rebuilds every site |
| Nightly 04:00 | `rollout.yml` deploys any enabled service whose floating tag now points at a different digest |
| Every 5 minutes | Each site's `wp-cron` scheduled task |
| Tuesdays 04:00 | NAT instance refresh |
| Wednesdays 03:00 | ECS host refresh: new host first, tasks move, old host goes |

## How to

### Run Terraform

From an `abd-cloud` checkout on an up-to-date `main` (the templates come from the checkout you run it in), with `abd-cloud-params` beside it:

```bash
cd abd-cloud
aws-vault exec abd_global -- ./tf-run.sh ../abd-cloud-params/abd-wordpress/wordpress-vpc/svc.blacklit-uk plan
aws-vault exec abd_global -- ./tf-run.sh ../abd-cloud-params/abd-wordpress/wordpress-vpc/svc.blacklit-uk apply
```

`abd_global` even for the `abd-wordpress` account: `tf-run.sh` assumes the `terraform` role in the target account. Applies are run by hand; a pull request to `abd-cloud` runs plans in CI. The operator scripts below use `abd_wp` with `--region=eu-west-1` instead.

### See what is running

```bash
aws-vault exec --region=eu-west-1 abd_wp -- aws ecs describe-services --cluster abd-wordpress-cluster \
  --services blacklit-uk --query 'services[0].{task:taskDefinition,running:runningCount,deployments:deployments[].{status:status,rollout:rolloutState}}'
```

Or the ECS console: cluster `abd-wordpress-cluster`, Services, then the service's Deployments and Events tabs.

### Read logs

Each service logs to `/ecs/abd-wordpress/<service>` for 14 days, one stream per task, prefixed with the container name (`web`).

```bash
aws-vault exec --region=eu-west-1 abd_wp -- aws logs tail /ecs/abd-wordpress/blacklit-uk --follow --since 30m
```

### Deploy an image

`deploy.yml` in `abd-cloud-containers`, from `main` only (the deploy role trusts nothing else). Pin a digest:

```bash
gh workflow run deploy.yml --ref main -f service=blacklit-uk -f container=web \
  -f image=800653036500.dkr.ecr.eu-west-1.amazonaws.com/abd/wp-blacklit-uk@sha256:<digest>
```

Find a tag's digest in ECR (`aws ecr describe-images --repository-name abd/wp-blacklit-uk --image-ids imageTag=8.3`). Deploying an older digest the same way is the emergency rollback to a previous image; ECR keeps the newest 30 dated images.

### Rebuild a site now

Actions, `sites`, Run workflow on `main`, with the domain or `all`. This also picks up the latest plugin and theme releases.

### Add a plugin or theme to a site

Edit `sites/<domain>/manifest.json` in `abd-cloud-containers` and open a PR; the PR builds and smoke tests the site. A premium item instead goes in `premium.json`, with its zip uploaded to `s3://abd-wordpress-html/premium/<name>/<version>.zip`; those only build on `main`.

### Move a site from the old host

In order; Dave runs every step that touches secrets.

1. **Image**: `sites/<domain>/` exists and the site builds on `main`; its ECR repository is in `container-registry`.
2. **Secrets**: compare, then write the 11 SSM parameters from the old `wp-config.php`. The script prints names and lengths, never values.
   ```bash
   aws-vault exec --region=eu-west-1 abd_wp -- images/wordpress-site/bin/wp-site-secrets.py split <domain> \
     --check ../abd-cloud-params/abd-wordpress/wordpress-vpc/svc.<service>/svc_config.tfvars
   aws-vault exec --region=eu-west-1 abd_wp -- images/wordpress-site/bin/wp-site-secrets.py split <domain> --apply
   ```
   Any `DIFF` line is a non-secret setting to correct in the tfvars.
3. **Uploads**: copy into the new access point directories (repeatable; `--dry-run` to preview).
   ```bash
   aws-vault exec --region=eu-west-1 abd_wp -- images/wordpress-site/bin/wp-efs-sync.sh <domain>
   ```
4. **Preview**: apply `svc.<service>` (preview hostname only), then deploy the image by digest. Check `https://<service>.abd-wp.uk/`: pages, images, wp-admin.
5. **Cutover**: final `wp-efs-sync.sh <domain> --delete`, then the cutover PR in `abd-cloud-params` (real domain in `WP_HOME`, `WP_SITEURL` and `hostnames`), apply, deploy. Add the domain to the `SITES_DEPLOY` repository variable in `abd-cloud-containers` so its builds roll out (once abd-cloud-containers#15 is merged; until then, deploy by hand).
6. **Rollback**: revert the cutover PR, apply, deploy. The old host never stopped serving the site's files and database.

daverix.ai takes daverix.uk's configuration: `split daverix.ai --from daverix.uk` and `wp-efs-sync.sh daverix.ai --w3tc-from daverix.uk`.

### Add a brand new site

`wp-site-secrets.py new <domain> --tfvars <svc_config.tfvars> --apply` generates the keys, salts and database password and asks for the SMTP login, then prints the SQL to create the database and user. After that it is steps 1, 4 and 5 above. See `images/wordpress-site/README.md` in `abd-cloud-containers`.

### Change a service's settings

Edit `svc.<service>/svc_config.tfvars`, PR, apply, then deploy. The apply registers a new task definition revision, but the service only runs it after the next deploy (Terraform ignores the service's revision; CI owns it).

### Get a shell in a container

ECS Exec is not enabled on any service today. To use it, set `enable_execute_command = true` in the service's tfvars, apply and deploy, then (with the Session Manager plugin installed):

```bash
aws-vault exec --region=eu-west-1 abd_wp -- aws ecs execute-command --cluster abd-wordpress-cluster \
  --task <task id> --container web --interactive --command /bin/sh
```

Switch it off again afterwards.

## Alerts

All go to the `abd-alerts` SNS topic by email.

| Alert | Means | First look |
|---|---|---|
| `deployment-failed` | A deployment could not complete; the circuit breaker has rolled back | The service's Events tab; the failed task's stopped reason and logs |
| `service-error` | ECS could not do something, usually place a task (no room on the hosts) | Events tab; host count and memory |
| `task-not-started` | A task never got going: image not found, secret not readable, mount failed | The stopped reason in the email |
| `task-exited` | An essential container exited non-zero (a crash, or a failed `wp-cron` run) | The logs, at the time in the email |
| `<service>` no healthy targets | The ALB has no healthy task for the service | Service events, `/healthz`, logs |

Expect one no-healthy-targets alert a few minutes after a new service is created: no data yet counts as unhealthy, on purpose.

## Problems we have actually hit

| Symptom | Cause | Fix |
|---|---|---|
| Plan fails: "Target group names are limited to 32 characters" | `abd-wordpress-<service>` is too long (analysisbydesign.co.uk) | Set `target_group_name` in the service's tfvars (abd-cloud-params#45) |
| `deploy.yml` fails with "rolled back" | New tasks failed 3 times; the circuit breaker put the old revision back. The site kept serving | Fix the cause, deploy again. Scheduled tasks use the latest revision, so `wp-cron` fails until the next good deploy |
| A service never updates after a failed deploy | (Fixed in abd-cloud-containers#13) the rollout treated the failed revision's digest as already deployed | Now only a COMPLETED primary deployment counts |
| An alert every 5 minutes | The task alert matched every finished `wp-cron` run | Fixed 2026-11-13 (abd-cloud#83): alerts only on a non-zero exit, as readable text |
| A new service's tasks fail to start | The service was applied before its image existed in ECR | Apply `svc.<service>` only after the site's first image is pushed |
| Site with premium items fails on a PR | The push role, which reads the premium zips, trusts `main` only | Expected; build on `main`, or locally with the zips unpacked in `.premium/<domain>/` |
| Site build fails the smoke test | A plugin or theme does not activate (amyegillin.uk: akismet with the pipdig theme) | Nothing is pushed and the running image stays. The test hides WP-CLI's output, so reproduce locally with `make build-site` and `make test-site` |
| `aws-vault` hangs | It waits for a keychain or MFA prompt | Run it yourself at the terminal |

## Not yet built

- daverix.uk's redirect to daverix.ai as an ALB rule (WP-05 ruling 10); the old host does it today.
- Spot capacity for burst (WP-04 ruling 23).
- Tulox and mortgage.daverix.ai on ECS, then retiring the old host and its ALB (programme step 7).
