# WP-08: WordPress Edit Copies (Parked)

**Repositories**: `abd-cloud-containers` (image flag, entrypoint, operator scripts, runbook), `abd-cloud-params` (the edit service target), `abd-cloud` only if the `compute/ecs-service` template needs a change.
**Status**: **Parked** (Dave, 2026-11-14). Reopen when a site owner needs to try designs, themes or plugins on their site. This document records the agreed shape so it can start from Discovery.
**Depends on**: WP-05 (per-site images, services, SSM secrets, EFS access points).
**Protocol**: Discovery, then Clarify (stop), then Build. See the programme overview.

## Why

Since WP-05, a live site's code comes only from its image. With `DISALLOW_FILE_MODS` set, owners can't install, update or delete plugins and themes. Asking for a manifest change is fine for one plugin. It doesn't work for an owner who wants to try a few designs: install themes, try plugins, and adjust settings until they're happy.

The alternative discussed was an EC2 sandbox with its own DNS, with the settings gathered by hand afterwards. It was set aside: it rebuilds a small old host for every request. An edit copy on ECS reuses the WP-05 pipeline instead.

## Settled

- **A separate edit copy, never a mode on the live service.** The live service stays immutable and keeps rolling out nightly while an owner experiments. A second ECS service runs from the same site image, with a flag that:
  - turns file changes back on;
  - mounts `wp-content/plugins` and `themes` from EFS, filled from the image on first start.
- **The edit copy has its own database**, copied from live at the start. Experiments never show on the live site.
- **On demand.** The edit copy is created when an owner asks and torn down at completion; nothing runs between uses.
- **Three steps**:
  1. **Start**: copy the database, snapshot its settings, and bring up the edit service on an `abd-wp.uk` hostname.
  2. **Owner experiments** on the edit copy, as freely and for as long as needed.
  3. **Complete**: read the edit copy and produce two outputs, then tear it down.
     - **A manifest PR** for `sites/<domain>/`.
       - The plugin and theme lists come from `wp plugin list` and `wp theme list`, in the old host's `manifest-export.sh` format.
       - Items not on wordpress.org have their zips taken from EFS into `s3://abd-wordpress-html/premium/<name>/<version>.zip` and listed in `premium.json`.
       - The PR build smoke tests it as usual.
     - **A settings change set**, reviewable as a file. It's applied to the live database with wp-cli after the merged image is live.
- Live content (posts, pages, orders, comments) is never copied back. Only design and configuration move.

## Phase 1: Discovery

1. **The base image's entrypoint and `wp-content` layout**: where an EFS mount can sit over `plugins` and `themes`, and how to fill it from the image's own copy on first start (the image must keep a copy outside the mounted paths).
2. **The `wp-config.php` constants** the flag must change:
   - `DISALLOW_FILE_MODS`, `DISALLOW_FILE_EDIT`, `AUTOMATIC_UPDATER_DISABLED`;
   - whether anything else assumes read-only code: the W3TC drop-in, `abd-wp-site-finish`.
3. **Database copy**:
   - how to dump and restore a site's database into a new one on the same RDS instance, run from a one-off ECS task;
   - the admin credentials it needs and who holds them (secret-touching steps are Dave's, WP-05 ruling 5);
   - a separate database user for the copy, with no rights on the live database, since the edit copy runs code the owner installed.
4. **URL handling in the copy**:
   - `wp search-replace` of the real domain with the edit hostname, which handles serialised data;
   - reversing it when the settings diff is taken, so the change set refers to the real domain.
5. **What a design change touches, per site**:
   - options: theme mods, `sidebars_widgets`, `widget_*`, `active_plugins`, plugin settings;
   - posts of type `custom_css`, `wp_template`, `wp_template_part`, `wp_global_styles`, `wp_navigation`, `nav_menu_item`;
   - menu terms;
   - any plugin tables. List which of the six sites' plugins keep settings in their own tables, as an options diff misses those.
6. **Options to leave out of the diff**:
   - transients, `cron`, `rewrite_rules`, `siteurl`, `home`, `recently_activated`;
   - anything a plugin rewrites on every request.
7. **Side effects on the edit copy**:
   - wp-cron (scheduled posts, newsletters, order emails);
   - outbound mail (WP Mail SMTP);
   - search engine indexing (`blog_public`, an `X-Robots-Tag` header).

   None of these must reach real people.
8. **Uploads**: the size of each site's uploads, which decides between copying them and mounting live's read-only.
9. **Capacity**: the room on the ECS hosts for one extra task (min 2, max 3 `t4g.small`).
10. **Running wp-cli against a service**: the pattern for one-off tasks with a command override (as `scheduled_tasks` does), for start, complete and apply.

## Phase 2: Clarify (minimum questions)

- **How settings get back to live**:
  - the options and design-posts diff, applied with wp-cli (recommended);
  - promoting the whole edit database, which needs a content freeze on live for the edit window;
  - the owner repeating the final settings on live by hand.
- **Uploads**:
  - copy them, with complete copying new files (add only) to live, so a new logo or header image comes across (recommended);
  - mount live's uploads read-only, which means the owner can't upload on the edit copy.
- **Access to the edit copy**:
  - WordPress login and `noindex` only (recommended for these sites);
  - ALB authentication (OIDC, for example Cognito) in front of the edit hostname;
  - an IP allow list.
- **Mail and cron on the edit copy**: both off (recommended), or mail redirected to Dave.
- **Shape in params**:
  - one `svc.<site>-edit` target per site, applied and destroyed on demand;
  - or a single edit target parameterised by site.
- **Change set apply and rollback**: the change set records each item's value before, so applying it in reverse undoes it (recommended); or rely on a database snapshot taken just before.
- **Names and placement** (Dave's, as always): the flag, the scripts, the edit hostname pattern, the service and params names, and where the runbook goes.
- **The pilot site**: oranjj.uk (a placeholder, nothing live) is the obvious first run.

## Phase 3: Build scope

1. **Base image**: the edit flag in `wp-config.php`, and the entrypoint step that fills EFS `plugins` and `themes` from the image when the flag is on. Live images behave exactly as now when it is off.
2. **Edit service**: the params target (and a template change only if `compute/ecs-service` can't already express it), with:
   - extra EFS access points;
   - the copy's database name, user and secrets;
   - mail and cron as ruled;
   - the edit hostname on the ALB.
3. **Start script**:
   - copy the database and create its user;
   - search-replace the hostname;
   - snapshot the settings;
   - copy uploads if ruled;
   - print the edit URL.
4. **Complete script**:
   - generate the manifest and premium changes as a branch for a PR;
   - upload premium zips;
   - write the settings change set;
   - list new uploads.
5. **Apply script**: apply the change set to live after the merged image is deployed, recording each item's previous value, and copy new uploads.
6. **Tear down**: destroy the edit service, drop the copy's database and user, and remove its EFS directories.
7. **Runbook** for the whole cycle, in the place ruled.
8. **Pilot** on the ruled site, end to end.

## Out of scope

- Any change to the live services' immutability, `DISALLOW_FILE_MODS` or the nightly rollout.
- Moving content (posts, pages, products, orders) from the edit copy to live.
- Settings kept in plugin tables, beyond flagging them in Discovery. Those are handled by hand, or by a later package if a site needs it.
- A permanent staging environment per site.

## Done when

- One full cycle on the pilot site: started, edited (a theme or plugin added and settings changed), completed, the manifest PR merged and deployed, the change set applied, and the edit copy torn down with nothing left behind (service, database, user, EFS directories).
- The live site served throughout and its image stayed the only source of its code.
- The runbook covers start, complete, apply, rollback of a change set, and tear down.

## Rulings

None yet.
