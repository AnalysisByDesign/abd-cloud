# WP-09: Retire the Old Host (Step 7)

**Repositories**: `abd-cloud-params` (most of the change), `abd-cloud-modules` (the `alb` module), `abd-cloud` (templates if needed, docs), `abd-cloud-packer` (AMI pipeline), `abd-cloud-containers` (docs).
**Status**: **Blocked until Tulox has moved to ECS (step 6).** Nothing in this package is actioned before then, Discovery included, because Discovery's findings depend on what Tulox leaves behind. Written 2026-11-14 so the agreed approach is on record.
**Depends on**: WP-05 (complete 2026-11-14), the Tulox package (step 6), WP-04's notes on the ALB transition.
**Protocol**: Discovery, then Clarify (stop), then Build. See the programme overview.

## Blocked until Tulox has moved

The old host (`abd-wordpress-ec2-asg`, one `t4g.medium` from the `abd-wp-php83-*` AMI) still runs Tulox. It also owns the only ALB, which every site's listener rule, certificate and DNS alias uses. Start this package only when all of the following are true:

- Tulox (web, worker, scheduler, Reverb) and mortgage.daverix.ai serve from ECS, and the Tulox package is complete.
- tulox.uk, tulox.co.uk, dev.tulox.uk and dr.tulox.uk no longer depend on the old host. Their `hosted-sites` targets point at the ALB (`trg_lb_name = "ec2-asg"`), and the dev and dr ones have it commented out.
- The old host serves no traffic of its own. Its target group's request count on the ALB's default action is flat at zero, apart from scanners.

Until then, the old host is also the WordPress sites' fallback (the primer's "Roll a site back to the old host"). That runbook route ends with this package.

## Why

Once Tulox has moved, the old host serves nothing, but it still costs a `t4g.medium`, carries the AMI pipeline and owns the ALB. Retiring it:

- closes the programme;
- frees the reserved instances for ECS hosts;
- removes the last Packer-built server.

## Settled

1. **ALB transition: build alongside, then tear down** (Dave, 2026-11-14).
   - A new ALB is built while the old one still runs. Every listener rule, certificate and DNS alias moves to it, then `app.wordpress` is destroyed whole, with its ALB.
   - No Terraform state manipulation: the new ALB is a new resource in another state, under a different name.
   - Two ALBs run only for the changeover (pennies).
   - The old host keeps serving as the fallback until the old ALB goes, so the outage is close to none. A short one is acceptable.
   - This replaces WP-04's note that the old ALB would be detached from `app.wordpress` state and kept.
2. **Fill the reserved instances.**
   - Two regional `t4g.medium` RIs (`bf12a06f...` and `32996921-20f3-45fc-98db-a65eb2ee13ee`, ending 2029-11-11) cover four `t4g.small` units.
   - Today the old host uses two of them and the ECS hosts two.
   - After retirement the ECS hosts grow to use all four (WP-04 ruling 21).
3. **The Packer AMI pipeline for the old host goes** (programme step 7).
4. **Programme leftovers** close here:
   - the Tulox POC ECR repository and `poc-tulox-image-fleet`, unless the Tulox package has already retired them (WP-02 rulings);
   - the NAT gateway remnants named in the programme overview;
   - the WP-05 ruling 11 tidy-up of rixinteriors.co.uk and abd.training.

## Phase 1: Discovery

1. **What `app.wordpress` owns.** List its state, then sort every resource into either moving to the new stack or being destroyed. At least:
   - the ASG and launch template;
   - the ALB, its listeners (443, and 80 redirecting to HTTPS) and the built-in target group (port 80, health check `/license.txt`);
   - the ALB security group `ec2-asg-alb`;
   - the ACM certificate for `abd-wp.uk` and `*.abd-wp.uk`;
   - the `abd-wp.uk` apex alias record (`dns_load_balancer`);
   - SQS, alarms, the scheduled refresh, IAM, key pairs.
2. **What references the old ALB by name**:
   - `trg_lb_name = "ec2-asg"` in thirteen `hosted-sites` targets (two commented out);
   - `load_balancer_name`, which defaults to `ec2-asg` in `compute/ecs-service`, used by every `svc.*`;
   - `ecs.hosts`' ingress rule from security group `ec2-asg-alb` to the dynamic host ports;
   - anything Tulox's services add.
3. **The new ALB in `ecs.hosts`.**
   - With `enable_load_balancer = true` it would be named `abd-wordpress-ecs-hosts`, with its own security group, certificate and `abd-wp.uk` apex alias.
   - **The apex alias clashes** with the old stack's record of the same name. Find how to defer it until the old one is destroyed: a toggle, or creating it afterwards.
   - The certificate: check it covers `*.abd-wp.uk`, for the preview hostnames and daverixuk.abd-wp.uk.
4. **The `alb` module's built-in target group.** It registers the ASG's instances on port 80, so it must become optional, with the default action a fixed response, before ECS hosts own an ALB (WP-04 notes). Existing callers must plan with no diff.
5. **Listener rule moves.** A target group can be attached to only one load balancer. Confirm that Terraform replaces each `svc.*` listener rule by destroying it on the old listener and creating it on the new one, and that the service keeps its target group throughout.
6. **The sequence file.** The six site `svc.*` targets (and the Tulox ones) are not in `sequence/prod.csv`; only `svc.hello` and `svc.smtp` are. Decide whether they join it before the re-applies.
7. **The 80-to-443 redirect** and any other listener settings on the old ALB that the new one must match.
8. **Traffic on the old host**: a week of request counts by host name on its target group, to show nothing is left. Also look for direct traffic that bypasses the ALB, such as cron or SSH jobs.
9. **What else the old host does**: hourly manifest exports, the WordPress boot-time updates (WP-05 ruling 36), local cron, backups to S3. Any of these may need a replacement, or a decision that it ends.
10. **Packer** (`abd-cloud-packer`):
    - **`wp-stack-ami`**: list the `abd-wp-php83-*` AMIs and their snapshots in account `813984516777`.
    - **`ubuntu-2404` and `amazon-linux-2023`** (x86): no params target uses them. Check the Tulox repository and any scripts before removing them.
    - **`tulox-image-fleet`** (a GPU ECS AMI): its fate comes from the Tulox package.
11. **Old copies**:
    - the per-site `/abd-wordpress/<domain>/wp-config.php` SSM parameters;
    - the old EFS trees `/mnt/efs/uploads/<site>` and `/mnt/efs/w3tc-config/<site>`, with their sizes;
    - the archived manifests in `s3://abd-wordpress-html/archive/`;
    - the old host's docroots, if they're on EFS.
12. **rixinteriors.co.uk and abd.training** (WP-05 ruling 11):
    - whether rixinteriors.co.uk's redirect to Facebook still needs its hosted zone;
    - whether the `app.training` ASG (Amazon Linux 2, x86, `prevent` in the sequence file) runs anything.
13. **NAT gateway remnants**: what the overview meant. Candidates are code paths and variables in the VPC module, and WP-01's "Rollback after teardown" runbook.
14. **Docs that describe the old host**:
    - architecture.md (the default action, status);
    - the primer (the rollback-to-old-host runbook, "no rule matches -> old host", the clock);
    - the WP-04 notes;
    - the programme overview.

## Phase 2: Clarify (minimum questions)

- **The new ALB's name and home**:
  - in `ecs.hosts`, as WP-04's notes say, named `abd-wordpress-ecs-hosts` (recommended);
  - or its own target.

  Names are Dave's.
- **Default action** once no old host exists: a fixed 404 (recommended), or a redirect to a chosen site.
- **How the name change reaches the targets**:
  - the `ecs-service` template default for `load_balancer_name` plus each `hosted-sites` file (recommended: the fewest edits);
  - or every target's params explicitly.
- **ECS hosts at full RI**:
  - four `t4g.small` (min 4) (recommended: matches the two-host spread and survives a host loss with room to spare);
  - or two `t4g.medium`.

  Also the ASG maximum above the RI.
- **Retention of the old copies** (EFS trees, `wp-config.php` parameters, AMIs and snapshots, the archive in S3): delete at teardown, or keep for a set time, for example 30 days, then delete (recommended: one EFS backup or snapshot first).
- **`abd-cloud-packer`**: archive the repository, or keep it for the Tulox fleet build, depending on the Tulox package.
- **rixinteriors.co.uk and abd.training**: delete their zones, or keep the zone where the domain still needs DNS.

## Phase 3: Build scope

In this order. Each step plans clean before the next.

1. **Module**: the `alb` module's built-in target group optional, with a fixed-response default action. Existing callers plan with no diff.
2. **New ALB alongside**: enable it in `ecs.hosts` (or as ruled), with its security group, certificate and listeners, and the `abd-wp.uk` apex record deferred.
   - `ecs.hosts`' ingress allows the new ALB's security group as well as the old.
3. **Move the listener rules**: re-apply every `svc.*` (the sites, Tulox, `hello`) against the new ALB.
   - Each host name briefly falls through to the old ALB's default action, the old host, which still serves it.
   - Check every site on the new ALB directly, for example with `curl --resolve`.
4. **Move certificates and DNS**: re-apply every `hosted-sites` target with the new `trg_lb_name`, which attaches each certificate to the new listener and repoints the aliases.
   - Check each domain: home page, www, `/healthz`, wp-admin.
   - daverix.uk's redirect rule moves with its `hosted-sites` target.
5. **Watch the old ALB drain**: request counts fall to scanners only (a day is enough).
6. **Tear down**:
   1. Remove `ecs.hosts`' ingress from `ec2-asg-alb`; otherwise the old security group cannot be deleted.
   2. Destroy `app.wordpress` with `tf-run.sh -o` (it is `protect` in the sequence file).
   3. Create the new stack's `abd-wp.uk` apex record.
   4. Remove `app.wordpress` from the sequence file.
7. **Fill the RI**: grow the ECS hosts as ruled, and confirm with the RI utilisation report.
8. **Packer**: deregister the `abd-wp-php83-*` AMIs and delete their snapshots, remove the `wp-stack-ami` build and the unused base builds as ruled, and archive or trim the repository.
9. **Tidy**: the old copies (retention as ruled), the POC ECR repository and `poc-tulox-image-fleet` if still there, the NAT gateway remnants, rixinteriors.co.uk and abd.training.
10. **Docs**: remove the old host from architecture.md and the primer (including the rollback-to-old-host runbook), close WP-04's ALB notes, and mark the programme complete in the overview.

## Out of scope

- Tulox's own move (step 6) and anything it leaves on ECS.
- Spot capacity (WP-04 ruling 23), WP-07 and WP-08, all parked.
- Moving off EC2 to Fargate (programme ruling 1, revisited when the RIs expire in 2029).

## Done when

- One ALB, owned by the ECS stack, serves every site and Tulox, with a fixed-response default action.
- No `abd-wordpress-ec2-asg` ASG, old ALB, `ec2-asg-alb` security group or `abd-wp-php83-*` AMIs or snapshots remain.
- The ECS hosts use all four RI units, and the RI utilisation report shows full use.
- The old copies are gone or on their ruled retention, and the Packer repository is archived or trimmed.
- The docs describe only the new platform, and the programme overview marks the programme complete.

## Rulings

1. **ALB transition: build alongside, then tear down** (Dave, 2026-11-14). See Settled 1.
2. **Blocked until Tulox has moved** (Dave, 2026-11-14). See the section above.
