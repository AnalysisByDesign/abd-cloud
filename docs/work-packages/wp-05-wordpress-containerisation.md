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
