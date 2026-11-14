# WP-05: WordPress Sites onto ECS

**Repositories**: the images repository (or a WordPress sites repository, per ruling), `abd-cloud-packer` (current manifests, read in Discovery), `abd-cloud` (services and listener rules).
**Depends on**: WP-03 (`abd-wordpress` image), WP-04 (cluster and service pattern).
**Blocks**: retirement of the old host. Tulox moves after this package.
**Protocol**: Discovery, then Clarify (stop), then Build. See the programme overview.

## Why

Five or six WordPress sites currently share one Packer-baked AMI that updates core, plugins and themes from per-site manifests at boot. That pattern does not survive containers: boot-time updates race on shared storage and make the running site drift from the tested image.

## Settled

- **Per-site image** built on `abd-wordpress`, applying that site's manifest **at build time**.
- **`DISALLOW_FILE_MODS`** is on; there is no admin-side install or update. The nightly build provides "always latest".
- **Nightly**: rebuild each site image, smoke test (container boots against a test database, homepage returns 200), push, roll the ECS service around 04:00. A failing smoke test stops the rollout and last night's image keeps running.
- **Only uploads on EFS**, through the site's access point.
- **One ECS service per site**, with hard memory limits.
- **Cutover by listener rule**: point the site's rule at its new target group (optionally weighted first), and roll back by pointing it back. No DNS change.
- **Pilot first**: one quiet site, then the rest.

## Phase 1: Discovery

1. The per-site manifest format and the boot-time update process in `abd-cloud-packer`: what it runs, in what order, and what state it keeps.
2. For each site: hostname, theme, plugins (beyond the common set), PHP settings, current memory use, and traffic level. Recommend the pilot.
3. **Plugins that write to disk** outside uploads: page caches, security plugins (for example Wordfence's `wflogs`), log files, minified asset caches, or generated CSS. With immutable code these need a writable path (tmpfs, EFS, or configuration pointing elsewhere), or they break silently.
4. WP-Cron: whether it runs from page loads or a system cron today.
5. `wp-config.php` handling: where secrets and salts come from, and per-site constants.
6. Database: per-site users and schemas on RDS, and whether `MAX_USER_CONNECTIONS` is set.
7. Anything else on the AMI that the sites depend on (mail sending, cron jobs, `.htaccess` or nginx rules, redirects).

## Phase 2: Clarify (minimum questions)

- **Where per-site images and manifests live**: in the images repository, a new WordPress sites repository, or left in `abd-cloud-packer` for now (Dave's leaning was to leave Packer as it is during the transition, so the AMI keeps serving the sites not yet moved).
- **Manifest format**: keep the current one unchanged, so the same file feeds both the AMI and the image during the overlap (recommended), or migrate it.
- **WP-Cron**: `DISABLE_WP_CRON` plus an ECS scheduled task (EventBridge) per site, or a cron sidecar.
- **Writable paths** for the plugins found in Discovery, decided per plugin.
- **The pilot site**.
- **PHP-FPM sizing** per site (`pm.max_children`), bounded by RDS connections: total equals tasks times `max_children` across every site and Tulox.
- **Per-site database users** with `MAX_USER_CONNECTIONS`, if not already in place.

## Phase 3: Build scope

1. The per-site image build from the manifest, the smoke test, and the nightly workflow.
2. The ECS service, target group, EFS access point and secrets per site, using the WP-04 pattern.
3. **Pilot cutover**: weighted rule (for example 10%), check logs and errors, move to 100%, and hold for at least one nightly rollout and one weekly host refresh before moving the next site.
4. The remaining sites, one at a time.
5. Remove each moved site from the AMI's boot-time update so the old host stops touching it.
6. A runbook covering adding a plugin to a site, emergency rollback to the previous image tag, and rollback to the old host.

## Out of scope

- Tulox.
- Retiring the old host and its AMI pipeline; that follows once Tulox has also moved.

## Done when

- Every WordPress site serves from ECS, and has survived a nightly rollout and a weekly host refresh.
- No WordPress code changes on a running container, and the image is the only source of plugins and themes.
- The old host serves no WordPress traffic.

## Rulings

Recorded 2026-11-12 (Dave), against the questions in `docs/discovery/wp-05.md`. Questions without a ruling are still open.

1. **Where images and manifests live**: `abd-cloud-containers`, beside the base images, using its build and its push role (`abd/*`). Directory layout and image naming are still Dave's to set.
2. **Manifest format**: the current JSON, unchanged, snapshotted into Git. The exporter's extra fields are ignored at build.
3. **Manifests until cutover**: the hourly export keeps running on the old host as a drift report, writing beside the live manifest rather than over the Git copy; differences are folded in. It stops for a site at that site's cutover.
4. **Premium plugins and themes**: versioned zips in a private S3 prefix (`<name>/<version>.zip`), fetched at build through the CI role's OIDC. Nothing licensed in Git.
5. **`wp-config.php`**: split into per-constant SSM parameters, injected as ECS `secrets`; the image carries one environment-driven `wp-config.php` with container paths and `X-Forwarded-Proto` handling. The current constants are listed site by site as each one comes up: Dave runs a script that prints every name but values only for an allow-list of non-secret settings (no `asm-exec` or Secrets Manager skill on this machine; Dave, 2026-11-12).
6. **Mail**: unchanged. WP Mail SMTP is installed on every site through the manifests and sends straight to IONOS; its `WPMS_*` settings move to SSM with the rest of `wp-config.php`. The bake-time copy under `/usr/share/wp-stack/mu-plugins/` is unused.
7. **WP-Cron**: `DISABLE_WP_CRON`, plus an EventBridge scheduled ECS task per site running due events.
8. **Uploads**: a new directory per site owned by 10001, behind the site's access point, filled by `rsync` at cutover. The old tree stays untouched for rollback to the old host.
9. **PHP**: 8.3 for the move, like for like; 8.5 per site afterwards.
10. **daverix.uk**: an ALB redirect rule (301 to `https://daverix.ai`), no image or task. Its parameter and manifest retire with the old host.
11. **rixinteriors.co.uk and abd.training**: out of scope. rixinteriors.co.uk redirects to Facebook from outside this stack; abd.training has an empty manifest. Their hosted zones, `wp-config.php` parameters, manifests and docroots are tidied when the old host retires.
12. **Pilots**: blacklit.uk first (typical stack, all wordpress.org), then amyegillin.uk (tests the premium path). Traffic is too low on either to matter.
13. **FPM**: `pm = ondemand`, `max_children` 10 per site. Sites already have their own database users (to be confirmed by the `wp-config.php` read), so no database change.
14. **Writable paths**: the W3TC page cache on tmpfs; `w3tc-config` on EFS in the site's access point beside uploads. Nothing else in the manifests writes outside `uploads/`.
15. **daverix.ai**: takes its configuration from daverix.uk's (`wp-config.php`, including the WP Mail SMTP settings, and W3TC config); they are the same site. daverix.ai's own manifest has neither plugin today.
16. **Premium items**: `pipdig-cultureshock` (amyegillin.uk) is paid for, and possibly one other, to be found by the first builds. Either may be refactored out later.
17. **Hosts** (WP-04 ruling 4): start on one `t4g.small`, then scale up to a `t4g.medium` or out to two `t4g.small` as the sites need.
18. **Layout in `abd-cloud-containers`**: one shared `images/wordpress-site/` (Dockerfile `FROM abd/wordpress:<php>` with a `SITE` build argument, `rootfs/` for `wp-config.php` and mu-plugins, `test.sh`); each site is data only under `sites/<domain>/` (`manifest.json`, plus `premium.json` and overrides where needed).
19. **ECR names**: `abd/wp-<site>`, dots as dashes (`abd/wp-blacklit-uk`), inside the existing push role's `abd/*` scope.
20. **Tags**: as the base images, an immutable `<php>-<yyyy.mm.dd>` plus a floating `<php>`. Deploys pin the digest.
21. **Workflow**: a new `sites.yml`: changed sites on pull requests and `main`, every site nightly after `build.yml`'s nightly, then the 04:00 rollout through WP-04's reusable deploy workflow.
22. **Makefile**: `make build-site SITE=<domain> [PHP=<ver>]`, `make test-site SITE=<domain>`, and `build-sites` / `test-sites` for all; the `IMAGE` targets are unchanged.
23. **Premium zips**: `s3://abd-wordpress-html/premium/<name>/<version>.zip`; the push role gets read on that prefix only.
24. **Plugin and theme versions**: builds install the current stable wordpress.org release of each manifest item; the manifest's version is ignored except for premium items. Each image records what it installed (`installed.json`), and the smoke test gates the rollout. No auto-updates inside WordPress (core, plugins or themes): updates come only from rebuilding and swapping the image, nightly and on demand (Dave, 2026-11-12).
25. **Service names**: each site's ECS service is named after its domain with dots as dashes, as `blacklit-uk`: params target `wordpress-vpc/svc.blacklit-uk`, task family `abd-wordpress-blacklit-uk`, log group `/ecs/abd-wordpress/blacklit-uk` (Dave, 2026-11-12).
26. **SSM names**: one SecureString per secret, named after the container's environment variable, `/abd-wordpress/<domain>/<VARIABLE>` (`/abd-wordpress/blacklit.uk/WORDPRESS_DB_PASSWORD`, the eight salts, `WPMS_SMTP_USER`, `WPMS_SMTP_PASS`). Non-secret settings (database name, user and host, WP Mail SMTP host, port and sender) go in the service's tfvars `environment` (Dave, 2026-11-12).
27. **Cutover**: preview first, then a straight switch. The service starts on a preview hostname, its service name under `abd-wp.uk` (`blacklit-uk.abd-wp.uk`, covered by the ALB's `*.abd-wp.uk` certificate), with `WP_HOME` and `WP_SITEURL` set to it, against the live database, for checking pages and admin. At cutover: `rsync` the uploads, set `WP_HOME` and `WP_SITEURL` to the real domain and add it to the service's `hostnames`. The domain's DNS and certificate stay with its `hosted-sites` target; the ALB's default action still sends it to the old host, so rolling back is removing it from `hostnames`. No weighted split (Dave, 2026-11-12).
28. **Site secrets process**: a script creates each site's SSM parameters; Terraform only references them by name, so no value reaches state, Git or an image. Moving sites are split from their `wp-config.php` parameter (checked against the service's tfvars first); new sites get generated keys, salts and database password, with the SMTP credentials entered by hand and the database user created on RDS from the printed SQL. SSM over Secrets Manager: standard parameters are free (Dave, 2026-11-12).
29. **Operator scripts**: in `abd-cloud-containers`, with the site builds, at `images/wordpress-site/bin/`: `wp-site-secrets.py` (`split` and `new`) and `wp-efs-sync.sh` (uploads and W3TC settings into the access point directories before cutover). The second premium item (ruling 16) is `business-owner` (baltihot.co.uk), delisted from wordpress.org (Dave, 2026-11-12).
30. **Rollout gate**: blacklit.uk then amyegillin.uk move first. No other site gets an ECS service (its `svc.<name>` target applied) until both are working on the container platform. Before amyegillin.uk's pipdig theme is uploaded to `s3://abd-wordpress-html/premium/`, the bucket is confirmed under Terraform (`wordpress-vpc/storage/s3.wordpress`). Until the premium zips are there, the amyegillin.uk and baltihot.co.uk builds fail on `main`; that is expected (Dave, 2026-11-12).
31. **Rollout gate, amended**: daverix.ai and analysisbydesign.co.uk move alongside amyegillin.uk rather than after it, and baltihot.co.uk moves once Dave has tested its preview himself, as it serves customers (Dave, 2026-11-13). In the event all three moved on 2026-11-13, before amyegillin.uk's image passed its smoke test.
32. **oranjj.uk skips the preview**: a placeholder with nothing live, so its first `svc.oranjj-uk` apply carries the real domain (Dave, 2026-11-14).
33. **Theme first-run setup in the smoke test**: a premium theme's entry in `sites/<domain>/premium.json` may carry `smoke`, wp-cli commands the smoke test runs after activating the theme, for one-off setup that the live database has long since done (Dave, 2026-11-14, option (a)).
34. **Platform documentation**: `docs/architecture.md` and `docs/ecs-primer.md` live in `abd-cloud-containers`; abd-cloud builds the infrastructure, and its README links there (Dave, 2026-11-14).
35. **Close-out**: the weekly host refresh is taken as proven by the rollouts already run, so WP-05 does not wait for 2026-11-18. daverix.uk's redirect moves to the ALB through the `hosted-sites` target's `redirect_to` (ruling 10). The old host stays until Tulox has moved; then its ASG is retired and the ECS hosts grow to fill the reserved instance quota (Dave, 2026-11-14).
36. **Scope item 5 dropped**: the old host keeps its boot-time updates for the moved sites until it is retired, and they go with it. That also keeps its copies current for the runbook's rollback to the old host (Dave, 2026-11-14).

## Status

**Complete on 2026-11-14.** All six sites serve from ECS and roll out nightly through `SITES_DEPLOY`. daverix.uk is an ALB redirect to daverix.ai (abd-cloud #87, abd-cloud-params #50, applied 2026-11-14), so the old host serves no WordPress traffic. The weekly host refresh counts as proven (ruling 35), and scope item 5 is dropped (ruling 36). The runbook (scope item 6) is the `Runbook` section of `abd-cloud-containers/docs/ecs-primer.md` (abd-cloud-containers #19). The old host stays as the sites' fallback until Tulox has moved; then its ASG goes and the ECS hosts grow to fill the reserved instance quota.

| Site | On ECS | Cutover |
|---|---|---|
| blacklit.uk | 2026-11-13 | abd-cloud-params #44 |
| daverix.ai | 2026-11-13 | abd-cloud-params #46 (W3TC settings and wp-config from daverix.uk, ruling 15) |
| analysisbydesign.co.uk | 2026-11-13 | abd-cloud-params #45 (target group name), #46 |
| baltihot.co.uk | 2026-11-13 | abd-cloud-params #47, after Dave's own preview test |
| amyegillin.uk | 2026-11-14 | abd-cloud-params #48, after abd-cloud-containers #17 |
| oranjj.uk | 2026-11-14 | abd-cloud-params #49, no preview (ruling 32) |
| daverix.uk | 2026-11-14 | ALB redirect to daverix.ai, abd-cloud #87 and abd-cloud-params #50 (ruling 10) |

Pipeline:
- abd-cloud-containers #15: `sites.yml` deploys each pushed site in `SITES_DEPLOY` through `rollout.yml`, and the nightly rollout includes them. Its first run, after the merge on 2026-11-13, rolled out all four sites then live.
- abd-cloud-containers #17: theme smoke commands (ruling 33), and wp-cli's error printed when a theme or plugin fails to activate.
- abd-cloud #83: ECS alerts on failures only, as readable text (WP-04 status).

Found while moving:
- **Target group names are limited to 32 characters**: `abd-wordpress-analysisbydesign-co-uk` is 36, so that service sets `target_group_name = "abd-wp-analysisbydesign-co-uk"` (abd-cloud-params #45).
- **www on the old host fell through to daverix.uk**: `www.baltihot.co.uk`, `www.amyegillin.uk`, `www.analysisbydesign.co.uk` and `www.oranjj.uk` redirected to daverix.ai: the old host answered them with daverix.uk's install (`X-Redirect-By: WordPress`). On ECS each www redirects to its own site.
- **pipdig-cultureshock's first-run setup** calls `wp_die()` for anyone not logged in until theme mod `p3_pinterest_theme_set` is set, and deletes the default themes. The live database ran it long ago; the smoke test's empty one had not, so amyegillin.uk failed with "plugin akismet does not activate" until ruling 33.
- **Mail From names** differed from the live wp-config.php on amyegillin.uk, analysisbydesign.co.uk and baltihot.co.uk; the services now use the live values ("Amy Gillin", "Dave Rix", "Balti Hot"). daverix.ai keeps daverix.uk's `no-reply@daverix.uk`, as its mailbox is daverix.uk's.
- **Between the cutover apply and the deploy**, the domain redirects to the preview hostname, because the running task still has the preview `WP_HOME`; deploy straight after the apply.
- Two images on analysisbydesign.co.uk's home page point at `new.analysisbydesign.co.uk`, which has no DNS; broken on the old host too, so left for a content fix.
