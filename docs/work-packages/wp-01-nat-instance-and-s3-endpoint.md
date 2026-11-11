# WP-01: Replace the NAT Gateway with a Self-Healing NAT Instance

**Repository**: `abd-cloud`
**Depends on**: nothing.
**Blocks**: nothing hard, but it goes first because it funds the migration overlap (about $32 a month saved, against about $7 a month for the instance and its public IP).
**Protocol**: Discovery, then Clarify (stop), then Build. See the programme overview.

## Why

The NAT gateway costs around $32 a month before data and is a large share of a roughly £145 monthly bill. A fck-nat instance does the same job for a fraction of that. This package is self-contained and reversible with one route change.

## Settled

- fck-nat AMI on a t4g.nano (arm64 is fine: the NAT is independent of the application RI).
- An ASG of one in a public subnet, with an auto-assigned public IPv4 address. No Elastic IP unless discovery finds a third party allow-listing the current NAT address.
- **Route-flip replacement, not a fixed ENI.** On boot the new instance disables source/destination checking on its own interface, confirms it can forward traffic, then calls `ec2:ReplaceRoute` on each private route table's `0.0.0.0/0` to point at itself. Only after the flip does it signal healthy.
- **Launch before terminate.** Instance refresh launches the replacement first. The old instance is terminated only after the new one has flipped the routes, then left a few minutes so in-flight connections drain.
- **Weekly instance refresh** as a drill, around 04:00.
- **S3 gateway endpoint** added to the existing **VPC module**, associated with the private route tables.
- **Extend the existing ASG module** for the NAT instance rather than writing a NAT-specific ASG.
- **The VPC module may create the NAT gateway itself.** If it does, it gains an option to turn NAT gateway creation off, defaulting to the current behaviour (on), so existing callers are unaffected. When it is off, the module must still create and expose the private route tables, with no default route of its own, so the NAT instance can own the `0.0.0.0/0` route. The production caller turns the gateway off only at the end of cutover.

## Phase 1: Discovery

Answer each of these in the report, with file paths:

1. The VPC module: its inputs and outputs, how route tables are created and exposed, how many NAT gateways it creates (one per AZ or a single one), and every caller.
2. Whether the VPC module creates the NAT gateway, its EIP and the private `0.0.0.0/0` route itself, and how tightly those are coupled to the route table resources. Specifically: can NAT creation be made conditional without forcing route table replacement (check `count` and `for_each` addressing, and whether `moved` blocks would be needed)?
3. Whether the VPC module already has any VPC endpoint support.
4. The ASG module: launch template handling, user data, instance refresh settings (including `max_healthy_percentage` or an equivalent), lifecycle hooks, IAM instance profile handling, network interface and public IP options, and every caller.
5. Whether anything references the NAT gateway ID or its EIP: outputs, security groups, other stacks, or documentation.
6. Whether any third party allow-lists the current NAT EIP. Check the code and documentation, then ask Dave.
7. Existing patterns for SSM parameters or AMI lookups, so the fck-nat AMI is resolved the same way.
8. Current NAT gateway data volumes from CloudWatch (`BytesOutToDestination`), if credentials allow, to confirm a t4g.nano is ample.

## Phase 2: Clarify (minimum questions)

- One NAT instance for all private subnets (cross-AZ data charge, single point of failure accepted), or one per AZ?
- How the route-flip logic is packaged: fck-nat's own options, a user data script in this repository, or a small script baked into a Packer image.
- How the ASG module should express "do not mark healthy until the post-boot action completes": a launch lifecycle hook completed by the instance, or the module's existing health mechanism.
- **The NAT toggle's shape** on the VPC module: a boolean such as `create_nat_gateway`, or a mode such as `nat_mode = "gateway" | "none"` that leaves room for the module to own the NAT instance itself later. Also, whether the private default route stays in the VPC module (pointing at whichever NAT target is passed in) or moves to the NAT stack. The route-flip design means the NAT instance rewrites that route at runtime, so if Terraform also manages it, it needs `ignore_changes` or it will fight the instance on every plan.
- Exact module interface additions, such as `enable_s3_gateway_endpoint` on the VPC module, and lifecycle hook, IAM policy attachment and public IP toggles on the ASG module. Names and shapes are Dave's call.
- Whether to add the DynamoDB gateway endpoint too (also free), or only S3.
- How long to keep the NAT gateway after cutover before deleting it (suggest 48 hours).

## Phase 3: Build scope

1. VPC module: an optional S3 gateway endpoint on the private route tables, defaulting off, so existing callers see no diff. Enable it in the production caller.
2. VPC module: the NAT gateway toggle per the ruling, defaulting on. Prove that flipping it off removes only the gateway, its EIP and the default route, and never replaces a route table or subnet.
3. ASG module: the minimum additions needed for the NAT use case, each defaulting to current behaviour.
4. The NAT instance stack: launch template, ASG of one, a security group allowing inbound from the VPC CIDR only, and an IAM role limited to `ec2:ModifyInstanceAttribute` on itself, `ec2:ReplaceRoute` on the named route table ARNs, `ec2:DescribeRouteTables`, and the `autoscaling:CompleteLifecycleAction` it needs.
5. A CloudWatch alarm on the NAT ASG having no healthy instance, plus a status check alarm, routed to Dave's existing alerting.
6. Cutover: apply the instance with the route flip, verify egress from a private host (`curl https://checkip.amazonaws.com` should return the NAT instance's IP), and run one manual instance refresh to confirm there is no egress gap. After the agreed hold period, set the VPC module's NAT toggle to off in the production caller, which removes the gateway and releases its EIP.
7. A short runbook covering how the flip works, how to roll back to a NAT gateway, and what an unplanned failure looks like.

## Out of scope

- Any change to the application hosts, ECS, or security groups beyond what egress needs.
- Interface VPC endpoints (excluded on cost).

## Done when

- The private subnets egress through the NAT instance, and the NAT gateway and its EIP are gone.
- The S3 gateway endpoint is in place and S3 traffic no longer traverses the NAT.
- A planned instance refresh completes with no measurable egress interruption.
- Every existing caller of the VPC and ASG modules plans with no diff apart from the intended production change.

## Rulings

Recorded 2026-11-10, against the questions in `docs/discovery/wp-01.md`.

1. **Third-party allow-listing**: none. The NAT instance uses an auto-assigned public IP. The NAT gateway's EIP goes when the gateway is torn down.
2. **NAT count**: one NAT instance for all private subnets, matching today, to reduce cost.
3. **Route flip packaging**: a user data script in the params repo (`abd-wordpress/wordpress-vpc/nat-instance/files/`), following the `app.wordpress` `cloud-init.sh` convention, on the stock fck-nat AMI. Nothing is baked. (Ruled 2026-11-11.)
4. **Healthy signal**: a launch lifecycle hook, completed by the instance after it has flipped the routes.
5. **Private default route ownership**: removed from Terraform state without destroying it (a `removed` block with `destroy = false`), so the NAT instance alone owns it.
6. **Public IP**: wire `require_public_ip` into the launch-template module. The NAT instance uses an auto-assigned (floating) public IP, so there is no confusion over which instance holds an address during a replacement. No static ENI and no EIP; the NAT gateway's EIP is released when the gateway is torn down. (An EIP hand-over was considered on 2026-11-11 and withdrawn.)
7. **Module interface names**: follow the existing style and naming conventions. Dave reviews before commit. `instance_refresh_max_healthy_percentage` defaults to **110** (in the `asg` module and `ec2-asg`), so refreshes launch the replacement before terminating the old instance; this is now wired through, which intentionally changes `app.wordpress`.
8. **Template**: refactor the existing `compute/ec2-asg` template rather than creating a new one. Add toggles (default on) for the ALB, SSL cert, DNS and ALB security groups, and for the RDS and EFS rules; add a subnet tier input (default `private_app`); pass the lifecycle hook and public IP through; add `moved` blocks for every module gaining a `count`. Proven by a no-diff plan on `app.wordpress` (and `app.training`). Params target: `abd-wordpress/wordpress-vpc/nat-instance`. (Ruled 2026-11-11.)
9. **Endpoints**: S3 only. DynamoDB is not used here.
10. **NAT gateway teardown**: no fixed hold period. Dave tears it down manually once satisfied, after several manual instance refreshes of the NAT instance have confirmed the flip works.
11. **Alerting**: create an SNS topic named `abd-alerts` in the `tf-templates/account` template, behind a variable that defaults to no topic (so `abd-global` plans with no diff), and enable it for `abd-wordpress`. Dave subscribes to it manually. (Ruled 2026-11-11.)

## Status

**As of 2026-11-11, 11:15. Cutover done; the work package stays open until the NAT gateway is torn down.**

Merged and applied:
- abd-cloud-modules #31: ASG max healthy percentage (110), lifecycle hooks, launch template public IP.
- abd-cloud #57: `ec2-asg` optional load balancer, RDS and EFS access, subnet tier, `moved` blocks.
- abd-cloud #58 and abd-cloud-params #26: the `abd-alerts` SNS topic. Dave is subscribed (email, confirmed).
- abd-cloud #56: `tf-run.sh` no longer auto-approves. #59: these documents. #54: `CLAUDE.md`.
- abd-cloud #60 and abd-cloud-params #27: the `nat-instance` target, `ec2-asg` alarms, route tables by AZ (`managed_route_table_azs`), ASG AZ pinning (`asg_availability_zones`), flip rollback, and the runbook.
- CI: the `GH_PAT` secret had expired. It was replaced on 2026-11-11 with a fine-grained token (Contents read-only on abd-cloud-params and abd-cloud-modules), and plans run again.

Cutover (Dave applied, 2026-11-11):
- 11:00:10: the first instance (`i-0d4c28732880821af`, eu-west-1b) launched. At 11:00:41 it switched all three private route tables away from `nat-047a0c1aab3d1fee7` and went InService. Both alarms are OK.
- Egress verified from the WordPress host: `checkip` returned the instance's IP (3.250.74.214). The sites are working.

Refresh drill 1 (manual, 100/110/60), 2026-11-11:
- 11:05:53: refresh started. 11:05:54: the replacement (`i-021977d9d248ed2e2`, eu-west-1c) launched into `Pending:Wait`.
- 11:06:28 to 11:06:29: the routes switched. A once-a-second `checkip` loop on the WordPress host went from 3.250.74.214 to 108.130.192.137 with **no failed requests**.
- The old instance went to `Terminating:Wait` after the warmup, drained for 120 seconds, and had terminated by 11:11:05. The refresh was **Successful** at 11:11:18.
- This meets the "planned refresh with no measurable egress interruption" requirement under Done when.

Done when, checked:
- [x] Private subnets egress through the NAT instance.
- [ ] The NAT gateway and its EIP are gone (still the rollback path).
- [x] The S3 gateway endpoint is in place (it already existed; confirmed in discovery).
- [x] A planned refresh with no measurable egress interruption (drill 1).
- [x] Existing callers plan with no diff (`app.wordpress`).

In progress:
- **Weekly scheduled refresh** (Settled): branch `feat/nat-weekly-refresh` in both repos. `ec2-asg` gains `asg_scheduled_refresh_expression` and `_timezone` (default off; `app.wordpress` plans clean). The target sets Tuesdays 04:00 Europe/London. EventBridge Scheduler calls `StartInstanceRefresh` directly, with no Lambda. Plans as 3 to add. See the runbook, "Weekly scheduled refresh".

Remaining before WP-01 closes:
1. A few more refresh drills. Ruling 10 leaves the teardown timing to Dave.
2. **Ruling 5 revisit**: a `removed` block can't be used while `aws_route.private_nat_gateway` is still declared in the VPC template. Recommended: `state rm` of `aws_route.private_nat_gateway[0..2]` through `tf-run.sh`, then `enable_nat_gateway = false`. See the runbook, "Teardown".
3. Tear down the NAT gateway. That releases `99.80.147.236`, and the rollback section of the runbook then no longer applies.

Open, not blocking:
- Naming: keep `nat-instance`, or rename to the `<role>.<name>` convention?
- No alert fires on a failed instance refresh. A failed weekly drill would leave the old instance in service without telling anyone. A candidate fix is an EventBridge rule on the instance-refresh-failed event that publishes to `abd-alerts`, which needs a topic policy allowing EventBridge.
- abd-cloud-params #28 (`app-ecs` renamed to `app.ecs`) is still open.

Known unrelated noise: `wordpress-vpc` shows a permanent in-place diff on the RDS parameter group `apply_method`. It predates WP-01.
